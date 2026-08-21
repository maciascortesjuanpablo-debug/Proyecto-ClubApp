import { notificacionModel } from '../models/notificaciones.js';

export const obtenerNotificaciones = async (req, res) => {
  try {
    res.json(await notificacionModel.listarPorUsuario(req.params.usuarioId));
  } catch (error) {
    console.error(error);
    res.status(500).json({ mensaje: 'Error al obtener las notificaciones', error: error.message });
  }
};

export const marcarNotificacionLeida = async (req, res) => {
  try {
    const notificacion = await notificacionModel.marcarLeida(req.params.id);
    res.json({ mensaje: 'Notificación marcada como leída', notificacion });
  } catch (error) {
    console.error(error);
    res.status(500).json({ mensaje: 'Error al actualizar la notificación', error: error.message });
  }
};