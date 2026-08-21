import { supabase } from '../config/supabase.js';

export const calendarioModel = {
  // SEDES
  async crearSede(sede) {
    const { data, error } = await supabase.from('sedes_canchas').insert(sede).select().single();
    if (error) throw error;
    return data;
  },
  async listarSedes() {
    const { data, error } = await supabase.from('sedes_canchas').select('*').order('nombre');
    if (error) throw error;
    return data;
  },

  // EVENTOS
  async crearEvento(evento) {
    const { data, error } = await supabase.from('eventos_calendario').insert(evento).select().single();
    if (error) throw error;
    return data;
  },
  async listarPorTorneo(torneo_id) {
    const { data, error } = await supabase
      .from('eventos_calendario')
      .select(`*, sedes_canchas(id, nombre, direccion, ciudad),
                equipo_local:equipo_local_id(id, nombre, logo_url),
                equipo_visitante:equipo_visitante_id(id, nombre, logo_url)`)
      .eq('torneo_id', torneo_id)
      .order('fecha', { ascending: true });
    if (error) throw error;
    return data;
  },
  async buscarPorId(id) {
    const { data, error } = await supabase
      .from('eventos_calendario')
      .select(`*, sedes_canchas(id, nombre, direccion, ciudad),
                equipo_local:equipo_local_id(id, nombre, logo_url),
                equipo_visitante:equipo_visitante_id(id, nombre, logo_url)`)
      .eq('id', id)
      .maybeSingle();
    if (error) throw error;
    return data;
  },
  async actualizar(id, cambios) {
    const { data, error } = await supabase.from('eventos_calendario').update(cambios).eq('id', id).select().single();
    if (error) throw error;
    return data;
  },
  async eliminar(id) {
    const { error } = await supabase.from('eventos_calendario').delete().eq('id', id);
    if (error) throw error;
  },

  // ÁRBITROS
  async asignarArbitro(datos) {
    const { data, error } = await supabase.from('partido_arbitros').insert(datos).select().single();
    if (error) throw error;
    return data;
  },
  async listarArbitrosPorEvento(evento_id) {
    const { data, error } = await supabase
      .from('partido_arbitros')
      .select('id, rol_arbitraje, usuarios(id, nombre, apellido)')
      .eq('evento_id', evento_id);
    if (error) throw error;
    return data;
  }
};