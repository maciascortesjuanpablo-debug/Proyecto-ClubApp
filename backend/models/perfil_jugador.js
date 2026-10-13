import { supabase } from '../config/supabase.js';
import { datos } from '../utils/helpers.js';

const perfiles = () => supabase.from('perfil_jugador');

export const perfilJugadorModel = {
  async crear(perfil) {
    return datos(await perfiles().insert(perfil).select().single());
  },
  async buscarPorUsuarioId(usuario_id) {
    return datos(await perfiles().select('*').eq('usuario_id', usuario_id).maybeSingle());
  },
  async actualizar(usuario_id, cambios) {
    return datos(await perfiles().update(cambios).eq('usuario_id', usuario_id).select().single());
  },
};
