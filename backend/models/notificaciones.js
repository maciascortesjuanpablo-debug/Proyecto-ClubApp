import { supabase } from '../config/supabase.js';
import { datos } from '../utils/helpers.js';

const notificaciones = () => supabase.from('notificaciones');

export const notificacionModel = {
  async crear(notificacion) {
    return datos(await notificaciones().insert(notificacion).select().single());
  },
  async listarPorUsuario(usuario_id) {
    return datos(await notificaciones().select('*').eq('usuario_id', usuario_id).order('creado_en', { ascending: false }));
  },
  // Solo si la notificación es del usuario
  async marcarLeida(id, usuario_id) {
    return datos(await notificaciones().update({ leida: true }).eq('id', id).eq('usuario_id', usuario_id).select().maybeSingle());
  },
};

// Las notificaciones son accesorias: si fallan no deben romper la acción principal
export const notificar = (usuario_id, titulo) =>
  notificacionModel.crear({ usuario_id, titulo }).catch((e) => console.error('No se pudo crear la notificación:', e.message));
