import { supabase } from '../config/supabase.js';
import { estadisticaModel } from '../models/estadisticas.js';
import { calendarioModel } from '../models/calendario.js';
import { equipoModel } from '../models/equipos.js';
import { torneoModel } from '../models/torneos.js';
import { ROLES, datos, entero, esAdmin, fallo } from '../utils/helpers.js';
import { esDuenoEquipo, esOrganizadorTorneo } from '../utils/permisos.js';

const NUMERICOS = ['goles', 'asistencias', 'tarjetas_amarillas', 'tarjetas_rojas', 'minutos_jugados'];
const LIMITES = { minutos_jugados: 300 };

// Admin; organizador del torneo del evento; árbitro asignado; o entrenador del equipo (si juega ese partido)
const puedeRegistrar = async (req, evento_id, equipo_id) => {
  if (esAdmin(req)) return true;
  const evento = await calendarioModel.buscarPorId(evento_id);
  if (!evento) return false;
  switch (req.usuario.rol_id) {
    case ROLES.ORGANIZADOR: return esOrganizadorTorneo(req, await torneoModel.buscarPorId(evento.torneo_id) ?? {});
    case ROLES.ARBITRO: return calendarioModel.esArbitroDelEvento(evento_id, req.usuario.id);
    case ROLES.ENTRENADOR: {
      const juega = [evento.equipo_local_id, evento.equipo_visitante_id].map(String).includes(String(equipo_id));
      return juega && esDuenoEquipo(req, await equipoModel.buscarPorId(equipo_id) ?? {});
    }
    default: return false;
  }
};

// Devuelve solo los campos numéricos presentes, validados; null si alguno es inválido
const leerNumericos = (body, porDefecto) => {
  const salida = {};
  for (const c of NUMERICOS) {
    if (body[c] === undefined && porDefecto === undefined) continue;
    const v = entero(body[c] ?? porDefecto, 0, LIMITES[c] ?? 99);
    if (v === null) return null;
    salida[c] = v;
  }
  return salida;
};

export const crearEstadistica = async (req, res) => {
  try {
    const { evento_id, usuario_id, equipo_id } = req.body;
    if (!evento_id || !usuario_id || !equipo_id) {
      return res.status(400).json({ mensaje: 'evento_id, usuario_id y equipo_id son obligatorios' });
    }
    const numeros = leerNumericos(req.body, 0);
    if (!numeros) return res.status(400).json({ mensaje: 'Las estadísticas deben ser números enteros válidos' });
    if (!(await puedeRegistrar(req, evento_id, equipo_id))) {
      return res.status(403).json({ mensaje: 'No puedes registrar estadísticas de este partido' });
    }

    const estadistica = await estadisticaModel.crear({ evento_id, usuario_id, equipo_id, ...numeros });
    res.status(201).json({ mensaje: 'Estadística registrada', estadistica });
  } catch (error) {
    fallo(res, error, 'Error al registrar la estadística');
  }
};

export const obtenerEstadisticasPorEvento = async (req, res) => {
  try {
    res.json(await estadisticaModel.listarPorEvento(req.params.eventoId));
  } catch (error) {
    fallo(res, error, 'Error al obtener las estadísticas');
  }
};

export const obtenerEstadisticasPorJugador = async (req, res) => {
  try {
    res.json(await estadisticaModel.listarPorJugador(req.params.usuarioId));
  } catch (error) {
    fallo(res, error, 'Error al obtener las estadísticas');
  }
};

export const actualizarEstadistica = async (req, res) => {
  try {
    const actual = await estadisticaModel.buscarPorId(req.params.id);
    if (!actual) return res.status(404).json({ mensaje: 'Estadística no encontrada' });

    const cambios = leerNumericos(req.body); // solo los contadores: evento, jugador y equipo no se reasignan
    if (!cambios || !Object.keys(cambios).length) return res.status(400).json({ mensaje: 'No hay estadísticas válidas para actualizar' });
    if (!(await puedeRegistrar(req, actual.evento_id, actual.equipo_id))) {
      return res.status(403).json({ mensaje: 'No puedes modificar estadísticas de este partido' });
    }

    res.json({ mensaje: 'Estadística actualizada', estadistica: await estadisticaModel.actualizar(req.params.id, cambios) });
  } catch (error) {
    fallo(res, error, 'Error al actualizar la estadística');
  }
};

export const eliminarEstadistica = async (req, res) => {
  try {
    await estadisticaModel.eliminar(req.params.id);
    res.json({ mensaje: 'Estadística eliminada' });
  } catch (error) {
    fallo(res, error, 'Error al eliminar la estadística');
  }
};

// Topes razonables para UN partido
const LIMITES_PARTIDO = { goles: 30, asistencias: 30, tarjetas_amarillas: 2, tarjetas_rojas: 1, minutos_jugados: 130 };
const CAMPO_BD = { goles: 'goles', asistencias: 'asistencias', tarjetas_amarillas: 'tarjetas_amarillas', tarjetas_rojas: 'tarjetas_rojas', minutos_jugados: 'minutos_jugados' };

// Guarda las estadísticas de varios jugadores de un partido a la vez (la pantalla "Registrar estadísticas").
// Cuerpo: { jugadores: [{ usuario_id, equipo_id, goles, asistencias, tarjetas_amarillas, tarjetas_rojas, minutos_jugados }] }
// Si un jugador ya tenía estadísticas en ese partido se actualizan (nunca se duplican); si no, se crean solo cuando hay algo que registrar.
export const guardarEstadisticasEvento = async (req, res) => {
  try {
    const evento = await calendarioModel.buscarPorId(req.params.eventoId);
    if (!evento) return res.status(404).json({ mensaje: 'Evento no encontrado' });
    if (evento.tipo !== 'Partido') return res.status(400).json({ mensaje: 'Solo los partidos tienen estadísticas de jugadores' });
    if (!['En vivo', 'Finalizado'].includes(evento.estado)) return res.status(409).json({ mensaje: 'Las estadísticas se registran cuando el partido está en vivo o finalizado' });

    const filas = req.body?.jugadores;
    if (!Array.isArray(filas) || !filas.length || filas.length > 80) return res.status(400).json({ mensaje: 'Envía entre 1 y 80 jugadores' });

    const equiposPartido = [evento.equipo_local_id, evento.equipo_visitante_id].map(String);
    const vistos = new Set();
    const limpias = [];
    for (const f of filas) {
      if (!f?.usuario_id || !f?.equipo_id) return res.status(400).json({ mensaje: 'Cada jugador necesita usuario_id y equipo_id' });
      if (!equiposPartido.includes(String(f.equipo_id))) return res.status(400).json({ mensaje: 'Hay jugadores de un equipo que no juega este partido' });
      if (vistos.has(String(f.usuario_id))) return res.status(400).json({ mensaje: 'Un jugador aparece repetido' });
      vistos.add(String(f.usuario_id));
      const numeros = {};
      for (const [campo, tope] of Object.entries(LIMITES_PARTIDO)) {
        const v = entero(f[campo] ?? 0, 0, tope);
        if (v === null) return res.status(400).json({ mensaje: `${campo.replace('_', ' ')} debe ser un número entre 0 y ${tope}` });
        numeros[CAMPO_BD[campo]] = v;
      }
      limpias.push({ usuario_id: f.usuario_id, equipo_id: f.equipo_id, ...numeros });
    }

    // Permiso por equipo: organizador, admin y árbitro asignado, o el entrenador dueño (solo su equipo)
    for (const equipo of new Set(limpias.map((f) => String(f.equipo_id)))) {
      if (!(await puedeRegistrar(req, evento.id, equipo))) return res.status(403).json({ mensaje: 'No puedes registrar estadísticas de este equipo en este partido' });
      const plantilla = (await equipoModel.listarJugadores(equipo)).map((j) => String(j.usuarios?.id));
      if (limpias.some((f) => String(f.equipo_id) === equipo && !plantilla.includes(String(f.usuario_id)))) {
        return res.status(400).json({ mensaje: 'Hay jugadores que no pertenecen a la plantilla del equipo' });
      }
    }

    const existentes = datos(await supabase.from('estadisticas_jugador').select('id, usuario_id').eq('evento_id', evento.id));
    let creadas = 0;
    let actualizadas = 0;
    for (const f of limpias) {
      const { usuario_id, equipo_id, ...numeros } = f;
      const previas = existentes.filter((e) => String(e.usuario_id) === String(usuario_id));
      if (previas.length) {
        await estadisticaModel.actualizar(previas[0].id, numeros);
        for (const duplicada of previas.slice(1)) await estadisticaModel.eliminar(duplicada.id); // limpia duplicados que hubiera de antes
        actualizadas++;
      } else if (Object.values(numeros).some((v) => v > 0)) {
        await estadisticaModel.crear({ evento_id: evento.id, usuario_id, equipo_id, ...numeros });
        creadas++;
      }
    }

    // Advertencias (no bloquean): los goles registrados deberían sumar el marcador
    const advertencias = [];
    if (evento.resultado_local != null && evento.resultado_visitante != null) {
      const [todas, equipos] = await Promise.all([
        estadisticaModel.listarPorEvento(evento.id),
        supabase.from('equipos').select('id, nombre').in('id', equiposPartido).then(datos),
      ]);
      const nombre = (id) => equipos.find((e) => String(e.id) === String(id))?.nombre ?? 'un equipo';
      const golesDe = (equipo) => todas.filter((s) => String(s.equipos?.id) === String(equipo)).reduce((a, s) => a + (s.goles ?? 0), 0);
      for (const [equipo, marcador] of [[evento.equipo_local_id, evento.resultado_local], [evento.equipo_visitante_id, evento.resultado_visitante]]) {
        const registrados = golesDe(equipo);
        if (registrados !== marcador) advertencias.push(`${nombre(equipo)}: goles registrados ${registrados}, marcador ${marcador}`);
      }
    }
    res.json({ mensaje: 'Estadísticas guardadas', creadas, actualizadas, advertencias });
  } catch (error) {
    fallo(res, error, 'Error al guardar las estadísticas');
  }
};