import { supabase } from '../config/supabase.js';

export const torneoModel = {

  async crear(torneo) {
    const { data, error } = await supabase
      .from('torneos')
      .insert(torneo)
      .select()
      .single();

    if (error) throw error;
    return data;
  },

  async listarTodos() {
    const { data, error } = await supabase
      .from('torneos')
      .select(`
        id, nombre, max_equipos, estado, jornada_actual, jornada_total, ciudad, creado_en,
        deportes ( id, nombre ),
        formatos ( id, nombre ),
        usuarios ( id, nombre, apellido )
      `)
      .order('creado_en', { ascending: false });

    if (error) throw error;
    return data;
  },

  async buscarPorId(id) {
    const { data, error } = await supabase
      .from('torneos')
      .select(`
        *,
        deportes ( id, nombre ),
        formatos ( id, nombre ),
        usuarios ( id, nombre, apellido )
      `)
      .eq('id', id)
      .maybeSingle();

    if (error) throw error;
    return data;
  },

  async listarPorOrganizador(organizador_id) {
    const { data, error } = await supabase
      .from('torneos')
      .select('*')
      .eq('organizador_id', organizador_id)
      .order('creado_en', { ascending: false });

    if (error) throw error;
    return data;
  },

  async actualizar(id, cambios) {
    const { data, error } = await supabase
      .from('torneos')
      .update(cambios)
      .eq('id', id)
      .select()
      .single();

    if (error) throw error;
    return data;
  },

  async eliminar(id) {
    const { error } = await supabase
      .from('torneos')
      .delete()
      .eq('id', id);

    if (error) throw error;
  },

  // ---- GRUPOS DEL TORNEO ----

  async crearGrupo({ torneo_id, nombre }) {
    const { data, error } = await supabase
      .from('grupos_torneo')
      .insert({ torneo_id, nombre })
      .select()
      .single();

    if (error) throw error;
    return data;
  },

  async listarGruposPorTorneo(torneo_id) {
    const { data, error } = await supabase
      .from('grupos_torneo')
      .select('*')
      .eq('torneo_id', torneo_id)
      .order('nombre');

    if (error) throw error;
    return data;
  }
};