import { notificacionModel } from '../models/notificaciones.js';
import { fallo } from '../utils/helpers.js';

export const obtenerNotificaciones = async (req, res) => {
  try {
    res.json(await notificacionModel.listarPorUsuario(req.params.usuarioId));
  } catch (error) {
    fallo(res, error, 'Error al obtener las notificaciones');
  }
};

export const marcarNotificacionLeida = async (req, res) => {
  try {
    const notificacion = await notificacionModel.marcarLeida(req.params.id, req.usuario.id);
    if (!notificacion) return res.status(404).json({ mensaje: 'Notificación no encontrada' });
    res.json({ mensaje: 'Notificación marcada como leída', notificacion });
  } catch (error) {
    fallo(res, error, 'Error al actualizar la notificación');
  }
};
