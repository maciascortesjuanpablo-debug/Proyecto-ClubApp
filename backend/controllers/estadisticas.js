import { estadisticaModel } from '../models/estadisticas.js';
import { calendarioModel } from '../models/calendario.js';
import { equipoModel } from '../models/equipos.js';
import { torneoModel } from '../models/torneos.js';
import { ROLES, entero, esAdmin, fallo } from '../utils/helpers.js';
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
