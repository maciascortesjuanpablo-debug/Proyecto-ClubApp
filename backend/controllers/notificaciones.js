import { notificacionModel } from '../models/notificaciones.js';
import { entero, fallo } from '../utils/helpers.js';

// Todas las notificaciones de un usuario (ruta histórica; el propio usuario o un admin)
export const obtenerNotificaciones = async (req, res) => {
  try {
    res.json(await notificacionModel.listarPorUsuario(req.params.usuarioId));
  } catch (error) {
    fallo(res, error, 'Error al obtener las notificaciones');
  }
};

// Mis notificaciones: ?limite=1..200 (por defecto 100) y ?no_leidas=1 para ver solo las pendientes
export const misNotificaciones = async (req, res) => {
  try {
    const limite = entero(req.query.limite, 1, 200) ?? 100;
    res.json(await notificacionModel.listarPorUsuario(req.usuario.id, { limite, soloNoLeidas: req.query.no_leidas === '1' }));
  } catch (error) {
    fallo(res, error, 'Error al obtener tus notificaciones');
  }
};

// Resumen liviano para consultar seguido: cuántas hay sin leer y las 5 más recientes sin leer
export const resumenNoLeidas = async (req, res) => {
  try {
    const [total, ultimas] = await Promise.all([
      notificacionModel.contarNoLeidas(req.usuario.id),
      notificacionModel.listarPorUsuario(req.usuario.id, { limite: 5, soloNoLeidas: true }),
    ]);
    res.json({ total, ultimas });
  } catch (error) {
    fallo(res, error, 'Error al consultar las notificaciones');
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

export const marcarTodasLeidas = async (req, res) => {
  try {
    await notificacionModel.marcarTodasLeidas(req.usuario.id);
    res.json({ mensaje: 'Todas las notificaciones quedaron como leídas' });
  } catch (error) {
    fallo(res, error, 'Error al actualizar las notificaciones');
  }
};

export const eliminarNotificacion = async (req, res) => {
  try {
    if (!(await notificacionModel.eliminar(req.params.id, req.usuario.id))) return res.status(404).json({ mensaje: 'Notificación no encontrada' });
    res.json({ mensaje: 'Notificación eliminada' });
  } catch (error) {
    fallo(res, error, 'Error al eliminar la notificación');
  }
};