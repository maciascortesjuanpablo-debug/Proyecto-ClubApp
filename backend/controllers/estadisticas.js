import { estadisticaModel } from '../models/estadisticas.js';

export const crearEstadistica = async (req, res) => {
  try {
    const { evento_id, usuario_id, equipo_id, goles, asistencias, tarjetas_amarillas, tarjetas_rojas, minutos_jugados } = req.body;
    if (!evento_id || !usuario_id || !equipo_id) {
      return res.status(400).json({ mensaje: 'evento_id, usuario_id y equipo_id son obligatorios' });
    }
    const estadistica = await estadisticaModel.crear({
      evento_id, usuario_id, equipo_id,
      goles: goles || 0, asistencias: asistencias || 0,
      tarjetas_amarillas: tarjetas_amarillas || 0, tarjetas_rojas: tarjetas_rojas || 0,
      minutos_jugados: minutos_jugados || 0
    });
    res.status(201).json({ mensaje: 'Estadística registrada', estadistica });
  } catch (error) {
    console.error(error);
    res.status(500).json({ mensaje: 'Error al registrar la estadística', error: error.message });
  }
};

export const obtenerEstadisticasPorEvento = async (req, res) => {
  try {
    res.json(await estadisticaModel.listarPorEvento(req.params.eventoId));
  } catch (error) {
    console.error(error);
    res.status(500).json({ mensaje: 'Error al obtener las estadísticas', error: error.message });
  }
};

export const obtenerEstadisticasPorJugador = async (req, res) => {
  try {
    res.json(await estadisticaModel.listarPorJugador(req.params.usuarioId));
  } catch (error) {
    console.error(error);
    res.status(500).json({ mensaje: 'Error al obtener las estadísticas', error: error.message });
  }
};

export const actualizarEstadistica = async (req, res) => {
  try {
    const estadistica = await estadisticaModel.actualizar(req.params.id, req.body);
    res.json({ mensaje: 'Estadística actualizada', estadistica });
  } catch (error) {
    console.error(error);
    res.status(500).json({ mensaje: 'Error al actualizar la estadística', error: error.message });
  }
};

export const eliminarEstadistica = async (req, res) => {
  try {
    await estadisticaModel.eliminar(req.params.id);
    res.json({ mensaje: 'Estadística eliminada' });
  } catch (error) {
    console.error(error);
    res.status(500).json({ mensaje: 'Error al eliminar la estadística', error: error.message });
  }
};