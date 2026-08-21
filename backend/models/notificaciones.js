import { supabase } from '../config/supabase.js';

export const notificacionModel = {
  async crear(notificacion) {
    const { data, error } = await supabase.from('notificaciones').insert(notificacion).select().single();
    if (error) throw error;
    return data;
  },
  async crearVarias(notificaciones) {
    const { data, error } = await supabase.from('notificaciones').insert(notificaciones).select();
    if (error) throw error;
    return data;
  },
  async listarPorUsuario(usuario_id) {
    const { data, error } = await supabase
      .from('notificaciones')
      .select('*')
      .eq('usuario_id', usuario_id)
      .order('creado_en', { ascending: false });
    if (error) throw error;
    return data;
  },
  async marcarLeida(id) {
    const { data, error } = await supabase.from('notificaciones').update({ leida: true }).eq('id', id).select().single();
    if (error) throw error;
    return data;
  }
};