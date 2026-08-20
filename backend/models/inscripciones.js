import { supabase } from '../config/supabase.js';

export const inscripcionModel = {

  // ---- INSCRIPCIONES ----

  async inscribirEquipo({ torneo_id, equipo_id }) {
    const { data, error } = await supabase
      .from('inscripciones_equipo')
      .insert({ torneo_id, equipo_id })
      .select()
      .single();

    if (error) throw error;
    return data;
  },

  async listarPorTorneo(torneo_id) {
    const { data, error } = await supabase
      .from('inscripciones_equipo')
      .select(`
        id, estado, fecha_inscripcion, grupo_id,
        equipos ( id, nombre, logo_url )
      `)
      .eq('torneo_id', torneo_id);

    if (error) throw error;
    return data;
  },

  async buscarPorId(id) {
    const { data, error } = await supabase
      .from('inscripciones_equipo')
      .select('*')
      .eq('id', id)
      .maybeSingle();

    if (error) throw error;
    return data;
  },

  async actualizarEstado(id, cambios) {
    const { data, error } = await supabase
      .from('inscripciones_equipo')
      .update(cambios)
      .eq('id', id)
      .select()
      .single();

    if (error) throw error;
    return data;
  },

  // ---- TABLA DE POSICIONES ----

  async crearTablaPosiciones(inscripcion_id) {
    const { data, error } = await supabase
      .from('tabla_posiciones')
      .insert({ inscripcion_id })
      .select()
      .single();

    if (error) throw error;
    return data;
  },

  async obtenerTablaPorTorneo(torneo_id) {
    const { data, error } = await supabase
      .from('tabla_posiciones')
      .select(`
        victorias, empates, derrotas, goles_favor, goles_contra, puntos, posicion,
        inscripciones_equipo!inner (
          torneo_id,
          equipos ( id, nombre, logo_url )
        )
      `)
      .eq('inscripciones_equipo.torneo_id', torneo_id)
      .order('puntos', { ascending: false });

    if (error) throw error;
    return data;
  },

  async actualizarPosicion(inscripcion_id, cambios) {
    const { data, error } = await supabase
      .from('tabla_posiciones')
      .update(cambios)
      .eq('inscripcion_id', inscripcion_id)
      .select()
      .single();

    if (error) throw error;
    return data;
  },

  // ---- INVITACIONES ----

  async crearInvitacion(datos) {
    const { data, error } = await supabase
      .from('invitaciones_equipo')
      .insert(datos)
      .select()
      .single();

    if (error) throw error;
    return data;
  },

  async listarInvitacionesPorUsuario(usuario_id) {
    const { data, error } = await supabase
      .from('invitaciones_equipo')
      .select(`
        id, posicion_propuesta, estado, creado_en,
        equipos ( id, nombre, logo_url )
      `)
      .eq('usuario_id', usuario_id)
      .eq('estado', 'Pendiente');

    if (error) throw error;
    return data;
  },

  async buscarInvitacionPorId(id) {
    const { data, error } = await supabase
      .from('invitaciones_equipo')
      .select('*')
      .eq('id', id)
      .maybeSingle();

    if (error) throw error;
    return data;
  },

  async actualizarInvitacion(id, cambios) {
    const { data, error } = await supabase
      .from('invitaciones_equipo')
      .update(cambios)
      .eq('id', id)
      .select()
      .single();

    if (error) throw error;
    return data;
  }
};