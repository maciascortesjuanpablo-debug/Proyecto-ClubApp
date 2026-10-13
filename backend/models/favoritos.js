import { supabase } from '../config/supabase.js';
import { datos } from '../utils/helpers.js';

const favoritos = () => supabase.from('favoritos');

export const favoritoModel = {
  async agregar(favorito) {
    return datos(await favoritos().insert(favorito).select().single());
  },
  async existe({ usuario_id, torneo_id, equipo_id }) {
    let q = favoritos().select('id').eq('usuario_id', usuario_id);
    q = torneo_id ? q.eq('torneo_id', torneo_id) : q.eq('equipo_id', equipo_id);
    return datos(await q.limit(1).maybeSingle());
  },
  async listarPorUsuario(usuario_id) {
    return datos(await favoritos()
      .select('*, torneos(id, nombre), equipos(id, nombre, logo_url)')
      .eq('usuario_id', usuario_id));
  },
  // Solo borra si el favorito pertenece al usuario; devuelve cuántos borró
  async eliminar(id, usuario_id) {
    return datos(await favoritos().delete().eq('id', id).eq('usuario_id', usuario_id).select('id')).length;
  },
};
