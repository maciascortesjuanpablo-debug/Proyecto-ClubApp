import { supabase } from '../config/supabase.js';

export const perfilJugadorModel = {

  async crear(perfil) {
    const { data, error } = await supabase
      .from('perfil_jugador')
      .insert(perfil)
      .select()
      .single();

    if (error) throw error;
    return data;
  },

  async buscarPorUsuarioId(usuario_id) {
    const { data, error } = await supabase
      .from('perfil_jugador')
      .select('*')
      .eq('usuario_id', usuario_id)
      .maybeSingle();

    if (error) throw error;
    return data;
  },

  async actualizar(usuario_id, cambios) {
    const { data, error } = await supabase
      .from('perfil_jugador')
      .update(cambios)
      .eq('usuario_id', usuario_id)
      .select()
      .single();

    if (error) throw error;
    return data;
  },

  async eliminar(usuario_id) {
    const { error } = await supabase
      .from('perfil_jugador')
      .delete()
      .eq('usuario_id', usuario_id);

    if (error) throw error;
  }
};