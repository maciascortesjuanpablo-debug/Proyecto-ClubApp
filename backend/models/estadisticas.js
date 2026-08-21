

import { supabase } from '../config/supabase.js';

export const estadisticaModel = {
  async crear(estadistica) {
    const { data, error } = await supabase.from('estadisticas_jugador').insert(estadistica).select().single();
    if (error) throw error;
    return data;
  },
  async listarPorEvento(evento_id) {
    const { data, error } = await supabase
      .from('estadisticas_jugador')
      .select('id, goles, asistencias, tarjetas_amarillas, tarjetas_rojas, minutos_jugados, usuarios(id, nombre, apellido), equipos(id, nombre)')
      .eq('evento_id', evento_id);
    if (error) throw error;
    return data;
  },
  async listarPorJugador(usuario_id) {
    const { data, error } = await supabase
      .from('estadisticas_jugador')
      .select('id, goles, asistencias, tarjetas_amarillas, tarjetas_rojas, minutos_jugados, creado_en, eventos_calendario(id, fecha, torneo_id)')
      .eq('usuario_id', usuario_id)
      .order('creado_en', { ascending: false });
    if (error) throw error;
    return data;
  },
  async actualizar(id, cambios) {
    const { data, error } = await supabase.from('estadisticas_jugador').update(cambios).eq('id', id).select().single();
    if (error) throw error;
    return data;
  },
  async eliminar(id) {
    const { error } = await supabase.from('estadisticas_jugador').delete().eq('id', id);
    if (error) throw error;
  }
};