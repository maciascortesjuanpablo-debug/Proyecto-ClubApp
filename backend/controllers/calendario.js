import { supabase } from '../config/supabase.js';
import { calendarioModel } from '../models/calendario.js';
import { torneoModel } from '../models/torneos.js';
import { inscripcionModel } from '../models/inscripciones.js';
import { FECHA_RE, HORA_RE, ROLES, ahora, datos, entero, esAdmin, fallo, pick, texto } from '../utils/helpers.js';
import { esOrganizadorTorneo } from '../utils/permisos.js';
import { recalcularSeguro } from '../utils/posiciones.js';

const ESTADOS = ['Programado', 'En vivo', 'Finalizado', 'Aplazado', 'Cancelado'];
const CAMPOS_AGENDA = ['fecha', 'hora', 'lugar_id', 'equipo_local_id', 'equipo_visitante_id'];

/* ---------- utilidades ---------- */

// Carga el torneo y comprueba que el usuario lo organiza; responde 404/403 y devuelve null si no
const torneoGestionable = async (req, res, torneo_id) => {
  const torneo = torneo_id ? await torneoModel.buscarPorId(torneo_id) : null;
  if (!torneo) return void res.status(404).json({ mensaje: 'Torneo no encontrado' });
  if (!esOrganizadorTorneo(req, torneo)) return void res.status(403).json({ mensaje: 'No organizas este torneo' });
  return torneo;
};

// Valida ?desde=AAAA-MM-DD&hasta=AAAA-MM-DD (máximo 100 días). Devuelve { desde, hasta } o { error }
const rango = ({ desde, hasta }) => {
  if (!FECHA_RE.test(desde ?? '') || !FECHA_RE.test(hasta ?? '')) return { error: 'Indica desde y hasta con formato AAAA-MM-DD' };
  if (desde > hasta) return { error: '"desde" no puede ser posterior a "hasta"' };
  if ((new Date(hasta) - new Date(desde)) / 86_400_000 > 100) return { error: 'El rango máximo es de 100 días' };
  return { desde, hasta };
};

// Agrega a cada evento los datos de su torneo (nombre y organizador)
const conTorneo = async (lista) => {
  const ids = [...new Set(lista.map((e) => e.torneo_id).filter(Boolean))];
  if (!ids.length) return lista;
  const torneos = datos(await supabase.from('torneos').select('id, nombre, organizador_id').in('id', ids));
  const porId = Object.fromEntries(torneos.map((t) => [t.id, t]));
  return lista.map((e) => ({ ...e, torneo: porId[e.torneo_id] ?? null }));
};

// El calendario solo programa hacia adelante: nada en días pasados ni en una hora de hoy que ya pasó.
// Devuelve el mensaje de error o null.
const errorDePasado = (fecha, hora) => {
  const hoy = ahora();
  if (fecha < hoy.fecha) return 'No se pueden programar eventos en fechas pasadas';
  if (fecha === hoy.fecha && String(hora).slice(0, 5) <= hoy.hora) return 'Esa hora de hoy ya pasó, elige una hora posterior';
  return null;
};

// Un partido necesita dos equipos distintos y aceptados en el torneo. Devuelve el mensaje de error o null
const validarPartido = async (torneo_id, local, visitante) => {
  if (!local || !visitante || String(local) === String(visitante)) return 'Un partido necesita dos equipos distintos';
  const aceptados = (await inscripcionModel.equiposAceptados(torneo_id)).map(String);
  return [local, visitante].every((e) => aceptados.includes(String(e))) ? null : 'Ambos equipos deben estar aceptados en el torneo';
};

// ¿Choca con otro evento del mismo día y hora (misma sede o algún equipo ocupado)? Devuelve el mensaje o null
const hayConflicto = async ({ fecha, hora, lugar_id, equipo_local_id, equipo_visitante_id }, excluirId) => {
  const mismaHora = (await calendarioModel.listarPorFecha(fecha)).filter(
    (e) => String(e.id) !== String(excluirId) && String(e.hora).slice(0, 5) === String(hora).slice(0, 5) && e.estado !== 'Cancelado',
  );
  if (lugar_id && mismaHora.some((e) => String(e.lugar_id) === String(lugar_id))) return 'Esa sede ya está ocupada a esa hora';
  const equipos = [equipo_local_id, equipo_visitante_id].filter(Boolean).map(String);
  if (mismaHora.some((e) => equipos.includes(String(e.equipo_local_id)) || equipos.includes(String(e.equipo_visitante_id)))) {
    return 'Uno de los equipos ya tiene un partido a esa hora';
  }
  return null;
};

// Equipos de un usuario: donde juega, donde es staff y los que creó
const equiposDelUsuario = async (usuario_id) => {
  const [jugador, staff] = await Promise.all([
    supabase.from('equipo_jugadores').select('equipo_id').eq('usuario_id', usuario_id).then(datos),
    supabase.from('equipo_staff').select('equipo_id').eq('usuario_id', usuario_id).then(datos),
  ]);
  let creados = [];
  try {
    creados = datos(await supabase.from('equipos').select('id').eq('creado_por', usuario_id)).map((e) => e.id);
  } catch { /* la columna creado_por puede no existir todavía */ }
  return [...new Set([...jugador.map((j) => j.equipo_id), ...staff.map((s) => s.equipo_id), ...creados])];
};

// Middleware: carga el evento de :id y exige ser organizador de su torneo
export const eventoGestionable = async (req, res, next) => {
  try {
    const evento = await calendarioModel.buscarPorId(req.params.id);
    if (!evento) return res.status(404).json({ mensaje: 'Evento no encontrado' });
    if (!(await torneoGestionable(req, res, evento.torneo_id))) return;
    req.evento = evento;
    next();
  } catch (error) {
    fallo(res, error, 'Error al verificar el evento');
  }
};

/* ---------- sedes ---------- */
export const crearSede = async (req, res) => {
  try {
    const nombre = texto(req.body.nombre, 120);
    if (!nombre) return res.status(400).json({ mensaje: 'El nombre de la sede es obligatorio' });
    const sede = await calendarioModel.crearSede({ nombre, direccion: texto(req.body.direccion, 200) || null, ciudad: texto(req.body.ciudad) || null });
    res.status(201).json({ mensaje: 'Sede creada', sede });
  } catch (error) {
    fallo(res, error, 'Error al crear la sede');
  }
};

export const obtenerSedes = async (req, res) => {
  try {
    res.json(await calendarioModel.listarSedes());
  } catch (error) {
    fallo(res, error, 'Error al obtener las sedes');
  }
};

/* ---------- calendario ---------- */

// Calendario general: todos los eventos entre dos fechas (público)
export const listarEventos = async (req, res) => {
  try {
    const r = rango(req.query);
    if (r.error) return res.status(400).json({ mensaje: r.error });
    const eventos = await calendarioModel.listarPorRango({ ...r, torneo_id: req.query.torneoId });
    res.json({ eventos: await conTorneo(eventos) });
  } catch (error) {
    fallo(res, error, 'Error al obtener el calendario');
  }
};

// "Mis partidos": donde juega mi equipo, donde soy árbitro o de los torneos que organizo (el admin ve todos)
export const misEventos = async (req, res) => {
  try {
    const r = rango(req.query);
    if (r.error) return res.status(400).json({ mensaje: r.error });

    if (esAdmin(req)) {
      const todos = await calendarioModel.listarPorRango(r);
      return res.json({ eventos: await conTorneo(todos.map((e) => ({ ...e, relacion: ['admin'] }))) });
    }

    const uid = req.usuario.id;
    // Cada rol ve solo lo suyo: jugador y entrenador, sus equipos; árbitro, sus designaciones; organizador, sus torneos
    const rol = req.usuario.rol_id;
    const [equipos, arbitrajes, torneos] = await Promise.all([
      rol === ROLES.JUGADOR || rol === ROLES.ENTRENADOR ? equiposDelUsuario(uid) : [],
      rol === ROLES.ARBITRO ? calendarioModel.eventosDeArbitro(uid) : [],
      rol === ROLES.ORGANIZADOR
        ? supabase.from('torneos').select('id').eq('organizador_id', uid).then(datos)
        : [],
    ]);
    const [local, visitante, arbitro, organizados] = await Promise.all([
      calendarioModel.listarEnRango('equipo_local_id', equipos, r),
      calendarioModel.listarEnRango('equipo_visitante_id', equipos, r),
      calendarioModel.listarEnRango('id', arbitrajes, r),
      calendarioModel.listarEnRango('torneo_id', torneos.map((t) => t.id), r),
    ]);

    const mapa = new Map();
    const agregar = (lista, relacion) => lista.forEach((e) => {
      const previo = mapa.get(e.id);
      mapa.set(e.id, { ...(previo ?? e), relacion: [...new Set([...(previo?.relacion ?? []), relacion])] });
    });
    agregar(local, 'equipo'); agregar(visitante, 'equipo'); agregar(arbitro, 'arbitro'); agregar(organizados, 'organizador');

    const ordenados = [...mapa.values()].sort((a, b) => `${a.fecha} ${a.hora}`.localeCompare(`${b.fecha} ${b.hora}`));
    res.json({ eventos: await conTorneo(ordenados) });
  } catch (error) {
    fallo(res, error, 'Error al obtener tus partidos');
  }
};

export const crearEvento = async (req, res) => {
  try {
    const { torneo_id, equipo_local_id, equipo_visitante_id, lugar_id } = req.body;
    const tipo = texto(req.body.tipo, 30);
    const { fecha, hora } = req.body;
    if (!torneo_id || !tipo || !fecha || !hora) {
      return res.status(400).json({ mensaje: 'torneo_id, tipo, fecha y hora son obligatorios' });
    }
    if (!FECHA_RE.test(fecha) || !HORA_RE.test(hora)) {
      return res.status(400).json({ mensaje: 'La fecha debe ser AAAA-MM-DD y la hora HH:MM' });
    }
    const pasado = errorDePasado(fecha, hora);
    if (pasado) return res.status(400).json({ mensaje: pasado });
    if (!(await torneoGestionable(req, res, torneo_id))) return;

    if (tipo === 'Partido') {
      const error = await validarPartido(torneo_id, equipo_local_id, equipo_visitante_id);
      if (error) return res.status(400).json({ mensaje: error });
    }
    const choque = await hayConflicto({ fecha, hora, lugar_id, equipo_local_id, equipo_visitante_id });
    if (choque) return res.status(409).json({ mensaje: choque });

    const evento = await calendarioModel.crearEvento({ torneo_id, tipo, equipo_local_id, equipo_visitante_id, fecha, hora, lugar_id });
    res.status(201).json({ mensaje: 'Evento creado', evento });
  } catch (error) {
    fallo(res, error, 'Error al crear el evento');
  }
};

export const obtenerEventosPorTorneo = async (req, res) => {
  try {
    res.json(await calendarioModel.listarPorTorneo(req.params.torneoId));
  } catch (error) {
    fallo(res, error, 'Error al obtener los eventos');
  }
};

// Detalle: el evento con su torneo (para saber quién lo organiza) y sus árbitros
export const obtenerEventoPorId = async (req, res) => {
  try {
    const evento = await calendarioModel.buscarPorId(req.params.id);
    if (!evento) return res.status(404).json({ mensaje: 'Evento no encontrado' });
    const [torneo, arbitros] = await Promise.all([torneoModel.buscarPorId(evento.torneo_id), calendarioModel.listarArbitrosPorEvento(evento.id)]);
    res.json({ ...evento, torneo: torneo && { id: torneo.id, nombre: torneo.nombre, organizador_id: torneo.organizador_id }, arbitros });
  } catch (error) {
    fallo(res, error, 'Error al obtener el evento');
  }
};

// Edición completa (organizador del torneo o admin)
export const actualizarEvento = async (req, res) => {
  try {
    const cambios = pick(req.body, ['tipo', 'equipo_local_id', 'equipo_visitante_id', 'fecha', 'hora', 'lugar_id', 'estado', 'resultado_local', 'resultado_visitante']);
    if (!Object.keys(cambios).length) return res.status(400).json({ mensaje: 'No hay campos válidos para actualizar' });
    if ((cambios.fecha && !FECHA_RE.test(cambios.fecha)) || (cambios.hora && !HORA_RE.test(cambios.hora))) {
      return res.status(400).json({ mensaje: 'La fecha debe ser AAAA-MM-DD y la hora HH:MM' });
    }
    if (cambios.estado && !ESTADOS.includes(cambios.estado)) return res.status(400).json({ mensaje: `El estado debe ser: ${ESTADOS.join(', ')}` });
    for (const c of ['resultado_local', 'resultado_visitante']) {
      if (cambios[c] != null && (cambios[c] = entero(cambios[c], 0, 99)) === null) {
        return res.status(400).json({ mensaje: 'Los resultados deben ser enteros entre 0 y 99' });
      }
    }

    const final = { ...req.evento, ...cambios };

    // Solo se revisa si realmente se mueve la fecha u hora (editar un evento ya pasado, p. ej. su sede, sigue permitido)
    const dia = (f) => String(f).split('T')[0];
    const movido = dia(final.fecha) !== dia(req.evento.fecha) || String(final.hora).slice(0, 5) !== String(req.evento.hora).slice(0, 5);
    if (movido) {
      const pasado = errorDePasado(dia(final.fecha), final.hora);
      if (pasado) return res.status(400).json({ mensaje: pasado });
    }

    // Si cambia la agenda o los equipos, se revisan de nuevo las reglas con los datos ya combinados
    if (CAMPOS_AGENDA.some((c) => c in cambios)) {
      if (final.tipo === 'Partido') {
        const error = await validarPartido(final.torneo_id, final.equipo_local_id, final.equipo_visitante_id);
        if (error) return res.status(400).json({ mensaje: error });
      }
      const choque = await hayConflicto(final, req.params.id);
      if (choque) return res.status(409).json({ mensaje: choque });
    }

    const evento = await calendarioModel.actualizar(req.params.id, cambios);
    await recalcularSeguro(req.evento.torneo_id); // los resultados cambian la tabla de posiciones
    res.json({ mensaje: 'Evento actualizado', evento });
  } catch (error) {
    fallo(res, error, 'Error al actualizar el evento');
  }
};

// Registrar estado y marcador: lo hace el organizador, el admin o el árbitro asignado al partido
export const registrarResultado = async (req, res) => {
  try {
    const evento = await calendarioModel.buscarPorId(req.params.id);
    if (!evento) return res.status(404).json({ mensaje: 'Evento no encontrado' });

    const torneo = await torneoModel.buscarPorId(evento.torneo_id);
    const permitido = (torneo && esOrganizadorTorneo(req, torneo)) || esAdmin(req) || (await calendarioModel.esArbitroDelEvento(evento.id, req.usuario.id));
    if (!permitido) return res.status(403).json({ mensaje: 'Solo el organizador o el árbitro asignado pueden registrar el resultado' });

    const cambios = pick(req.body, ['estado', 'resultado_local', 'resultado_visitante']);
    if (!Object.keys(cambios).length) return res.status(400).json({ mensaje: 'Indica el estado o el marcador' });
    if (cambios.estado && !ESTADOS.includes(cambios.estado)) return res.status(400).json({ mensaje: `El estado debe ser: ${ESTADOS.join(', ')}` });
    for (const c of ['resultado_local', 'resultado_visitante']) {
      if (cambios[c] != null && (cambios[c] = entero(cambios[c], 0, 99)) === null) {
        return res.status(400).json({ mensaje: 'Los resultados deben ser enteros entre 0 y 99' });
      }
    }

    const final = { ...evento, ...cambios };
    if (final.estado === 'Finalizado' && (final.resultado_local == null || final.resultado_visitante == null)) {
      return res.status(400).json({ mensaje: 'Para finalizar el partido indica el marcador de los dos equipos' });
    }

    const actualizado = await calendarioModel.actualizar(evento.id, cambios);
    await recalcularSeguro(evento.torneo_id); // la tabla de posiciones se actualiza sola
    res.json({ mensaje: 'Resultado registrado', evento: actualizado });
  } catch (error) {
    fallo(res, error, 'Error al registrar el resultado');
  }
};

export const eliminarEvento = async (req, res) => {
  try {
    await calendarioModel.eliminar(req.params.id);
    await recalcularSeguro(req.evento.torneo_id);
    res.json({ mensaje: 'Evento eliminado' });
  } catch (error) {
    fallo(res, error, 'Error al eliminar el evento');
  }
};

/* ---------- árbitros ---------- */

// Árbitros que se pueden asignar (para el organizador)
export const arbitrosDisponibles = async (req, res) => {
  try {
    const arbitros = datos(await supabase.from('usuarios').select('id, nombre, apellido').eq('rol_id', ROLES.ARBITRO).eq('activo', true).order('nombre').limit(200));
    res.json({ arbitros });
  } catch (error) {
    fallo(res, error, 'Error al obtener los árbitros');
  }
};

export const asignarArbitro = async (req, res) => {
  try {
    const { usuario_id, rol_arbitraje } = req.body;
    if (!usuario_id) return res.status(400).json({ mensaje: 'usuario_id es obligatorio' });
    if (await calendarioModel.esArbitroDelEvento(req.params.id, usuario_id)) {
      return res.status(409).json({ mensaje: 'Ese árbitro ya está asignado al evento' });
    }
    const arbitro = await calendarioModel.asignarArbitro({ evento_id: req.params.id, usuario_id, rol_arbitraje: rol_arbitraje || 'Principal' });
    res.status(201).json({ mensaje: 'Árbitro asignado', arbitro });
  } catch (error) {
    fallo(res, error, 'Error al asignar el árbitro');
  }
};

export const quitarArbitro = async (req, res) => {
  try {
    if (!(await calendarioModel.eliminarArbitro(req.params.id, req.params.arbitroId))) {
      return res.status(404).json({ mensaje: 'Ese árbitro no está asignado al evento' });
    }
    res.json({ mensaje: 'Árbitro retirado del evento' });
  } catch (error) {
    fallo(res, error, 'Error al retirar el árbitro');
  }
};

export const obtenerArbitrosPorEvento = async (req, res) => {
  try {
    res.json(await calendarioModel.listarArbitrosPorEvento(req.params.id));
  } catch (error) {
    fallo(res, error, 'Error al obtener los árbitros');
  }
};