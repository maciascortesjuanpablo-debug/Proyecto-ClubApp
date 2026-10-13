import { supabase } from '../config/supabase.js';

const SELECT_PARTIDO = `
  id, fecha, hora, estado, resultado_local, resultado_visitante, creado_en,
  torneos ( id, nombre, jornada_actual ),
  equipo_local:equipo_local_id ( id, nombre, logo_url ),
  equipo_visitante:equipo_visitante_id ( id, nombre, logo_url )
`;

export const homeModel = {

  async partidoEnVivo() {
    const { data, error } = await supabase
      .from('eventos_calendario')
      .select(SELECT_PARTIDO)
      .eq('tipo', 'Partido')
      .eq('estado', 'En vivo')
      .order('fecha', { ascending: false })
      .limit(1)
      .maybeSingle();
    if (error) throw error;
    return data;
  },

  async partidosDestacados(limite = 6) {
    const { data, error } = await supabase
      .from('eventos_calendario')
      .select(SELECT_PARTIDO)
      .eq('tipo', 'Partido')
      .order('fecha', { ascending: false })
      .order('hora', { ascending: false })
      .limit(limite);
    if (error) throw error;
    return data;
  },

  async ultimosResultados(limite = 3) {
    const { data, error } = await supabase
      .from('eventos_calendario')
      .select(SELECT_PARTIDO)
      .eq('tipo', 'Partido')
      .eq('estado', 'Finalizado')
      .order('creado_en', { ascending: false })
      .limit(limite);
    if (error) throw error;
    return data;
  },

  async torneosActivos(limite = 5) {
    const { data, error } = await supabase
      .from('torneos')
      .select('id, nombre, max_equipos, estado, jornada_actual, jornada_total, ciudad, creado_en, deportes ( nombre ), formatos ( nombre )')
      .eq('estado', 'Activo')
      .order('creado_en', { ascending: false })
      .limit(limite);
    if (error) throw error;
    return data;
  },

  async ultimosTorneos(limite = 3) {
    const { data, error } = await supabase
      .from('torneos')
      .select('id, nombre, creado_en')
      .order('creado_en', { ascending: false })
      .limit(limite);
    if (error) throw error;
    return data;
  },

  // ---------- Solo usuarios logueados ----------

  async estadisticasUsuario(usuario_id) {
    const { data: stats, error } = await supabase
      .from('estadisticas_jugador')
      .select('goles')
      .eq('usuario_id', usuario_id);
    if (error) throw error;

    const partidos = stats.length;
    const goles = stats.reduce((acc, s) => acc + (s.goles || 0), 0);

    // Partidos registrados en los últimos 7 días ("+N esta semana")
      const { count: partidosSemana, error: e0 } = await supabase
        .from('estadisticas_jugador')
        .select('id', { count: 'exact', head: true })
        .eq('usuario_id', usuario_id)
        .gte('creado_en', new Date(Date.now() - 7 * 24 * 3600 * 1000).toISOString());
      if (e0) throw e0;

    const { data: equipos, error: e2 } = await supabase
      .from('equipo_jugadores')
      .select('equipo_id')
      .eq('usuario_id', usuario_id);
    if (e2) throw e2;

    let torneos = 0;
    if (equipos.length > 0) {
      const { data: insc, error: e3 } = await supabase
        .from('inscripciones_equipo')
        .select('torneo_id, torneos!inner ( estado )')
        .in('equipo_id', equipos.map(e => e.equipo_id))
        .eq('estado', 'Aceptado')
        .eq('torneos.estado', 'Activo');
      if (e3) throw e3;
      torneos = new Set(insc.map(i => i.torneo_id)).size;
    }

    return { partidos, partidosSemana: partidosSemana || 0, goles, torneos };
  },

  async notificacionesNoLeidas(usuario_id) {
    const { count, error } = await supabase
      .from('notificaciones')
      .select('id', { count: 'exact', head: true })
      .eq('usuario_id', usuario_id)
      .eq('leida', false);
    if (error) throw error;
    return count || 0;
  },

  async notificacionesRecientes(usuario_id, limite = 5) {
    const { data, error } = await supabase
      .from('notificaciones')
      .select('titulo, creado_en')
      .eq('usuario_id', usuario_id)
      .order('creado_en', { ascending: false })
      .limit(limite);
    if (error) throw error;
    return data;
  }
};