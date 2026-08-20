import { supabase } from '../config/supabase.js';

export const codigoVerificacionModel = {

  async crear({ usuario_id, codigo, tipo, expira_en }) {
    const { data, error } = await supabase
      .from('codigos_verificacion')
      .insert({ usuario_id, codigo, tipo, expira_en })
      .select()
      .single();

    if (error) throw error;
    return data;
  },

  async buscarValido({ usuario_id, codigo }) {
    const { data, error } = await supabase
      .from('codigos_verificacion')
      .select('*')
      .eq('usuario_id', usuario_id)
      .eq('codigo', codigo)
      .eq('usado', false)
      .gte('expira_en', new Date().toISOString())
      .order('creado_en', { ascending: false })
      .limit(1)
      .maybeSingle();

    if (error) throw error;
    return data;
  },

  async marcarUsado(id) {
    const { error } = await supabase
      .from('codigos_verificacion')
      .update({ usado: true })
      .eq('id', id);

    if (error) throw error;
  }
};