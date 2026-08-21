import { supabase } from '../config/supabase.js';

export const favoritoModel = {
  async agregar(favorito) {
    const { data, error } = await supabase.from('favoritos').insert(favorito).select().single();
    if (error) throw error;
    return data;
  },
  async listarPorUsuario(usuario_id) {
    const { data, error } = await supabase
      .from('favoritos')
      .select('*, torneos(id, nombre), equipos(id, nombre, logo_url)')
      .eq('usuario_id', usuario_id);
    if (error) throw error;
    return data;
  },
  async eliminar(id) {
    const { error } = await supabase.from('favoritos').delete().eq('id', id);
    if (error) throw error;
  }
};