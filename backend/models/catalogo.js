import { supabase } from '../config/supabase.js';

export const catalogoModel = {

  //ROLES

  async listarRoles() {
    const { data, error } = await supabase
      .from('roles')
      .select('*')
      .order('id', { ascending: true });

    if (error) throw error;
    return data;
  },

  async buscarRolPorId(id) {
    const { data, error } = await supabase
      .from('roles')
      .select('*')
      .eq('id', id)
      .maybeSingle();

    if (error) throw error;
    return data;
  },

  //DEPORTES

  async listarDeportes() {
    const { data, error } = await supabase
      .from('deportes')
      .select('*')
      .order('nombre', { ascending: true });

    if (error) throw error;
    return data;
  },

  async buscarDeportePorId(id) {
    const { data, error } = await supabase
      .from('deportes')
      .select('*')
      .eq('id', id)
      .maybeSingle();

    if (error) throw error;
    return data;
  },

  //FORMATOS

  async listarFormatos() {
    const { data, error } = await supabase
      .from('formatos')
      .select('*')
      .order('nombre', { ascending: true });

    if (error) throw error;
    return data;
  },

  async buscarFormatoPorId(id) {
    const { data, error } = await supabase
      .from('formatos')
      .select('*')
      .eq('id', id)
      .maybeSingle();

    if (error) throw error;
    return data;
  }
};