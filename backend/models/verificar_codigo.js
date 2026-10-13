import { supabase } from '../config/supabase.js';
import { datos } from '../utils/helpers.js';

const codigos = () => supabase.from('codigos_verificacion');

export const codigoVerificacionModel = {
  async crear({ usuario_id, codigo, tipo, expira_en }) {
    return datos(await codigos().insert({ usuario_id, codigo, tipo, expira_en }).select().single());
  },

  async buscarValido({ usuario_id, codigo }) {
    return datos(await codigos()
      .select('*')
      .eq('usuario_id', usuario_id)
      .eq('codigo', codigo)
      .eq('usado', false)
      .gte('expira_en', new Date().toISOString())
      .order('creado_en', { ascending: false })
      .limit(1)
      .maybeSingle());
  },

  async marcarUsado(id) {
    datos(await codigos().update({ usado: true }).eq('id', id));
  },

  // Anula los códigos pendientes del usuario (al pedir uno nuevo o al agotar intentos)
  async invalidarPendientes(usuario_id, tipo) {
    datos(await codigos().update({ usado: true }).eq('usuario_id', usuario_id).eq('tipo', tipo).eq('usado', false));
  },
};
