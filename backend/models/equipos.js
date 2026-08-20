import { supabase } from '../config/supabase.js';

export const equipoModel = {

  async crear(equipo) {
    const { data, error } = await supabase
      .from('equipos')
      .insert(equipo)
      .select()
      .single();

    if (error) throw error;
    return data;
  },

  async listarTodos() {
    const { data, error } = await supabase
      .from('equipos')
      .select('*')
      .order('creado_en', { ascending: false });

    if (error) throw error;
    return data;
  },

  async buscarPorId(id) {
    const { data, error } = await supabase
      .from('equipos')
      .select('*')
      .eq('id', id)
      .maybeSingle();

    if (error) throw error;
    return data;
  },

  async actualizar(id, cambios) {
    const { data, error } = await supabase
      .from('equipos')
      .update(cambios)
      .eq('id', id)
      .select()
      .single();

    if (error) throw error;
    return data;
  },

  async eliminar(id) {
    const { error } = await supabase
      .from('equipos')
      .delete()
      .eq('id', id);

    if (error) throw error;
  },

  // ---- JUGADORES DEL EQUIPO ----

  async agregarJugador(datos) {
    const { data, error } = await supabase
      .from('equipo_jugadores')
      .insert(datos)
      .select()
      .single();

    if (error) throw error;
    return data;
  },

  async listarJugadores(equipo_id) {
    const { data, error } = await supabase
      .from('equipo_jugadores')
      .select(`
        id, posicion, dorsal, estado_convocatoria, es_titular, creado_en,
        usuarios ( id, nombre, apellido, correo )
      `)
      .eq('equipo_id', equipo_id);

    if (error) throw error;
    return data;
  },

  async actualizarJugador(equipo_id, usuario_id, cambios) {
    const { data, error } = await supabase
      .from('equipo_jugadores')
      .update(cambios)
      .eq('equipo_id', equipo_id)
      .eq('usuario_id', usuario_id)
      .select()
      .single();

    if (error) throw error;
    return data;
  },

  async eliminarJugador(equipo_id, usuario_id) {
    const { error } = await supabase
      .from('equipo_jugadores')
      .delete()
      .eq('equipo_id', equipo_id)
      .eq('usuario_id', usuario_id);

    if (error) throw error;
  },

  // ---- STAFF DEL EQUIPO ----

  async agregarStaff(datos) {
    const { data, error } = await supabase
      .from('equipo_staff')
      .insert(datos)
      .select()
      .single();

    if (error) throw error;
    return data;
  },

  async listarStaff(equipo_id) {
    const { data, error } = await supabase
      .from('equipo_staff')
      .select(`
        id, cargo, creado_en,
        usuarios ( id, nombre, apellido, correo )
      `)
      .eq('equipo_id', equipo_id);

    if (error) throw error;
    return data;
  },

  async eliminarStaff(equipo_id, usuario_id) {
    const { error } = await supabase
      .from('equipo_staff')
      .delete()
      .eq('equipo_id', equipo_id)
      .eq('usuario_id', usuario_id);

    if (error) throw error;
  }
};