import { supabase } from '../config/supabase.js';
import { datos } from '../utils/helpers.js';

const inscripciones = () => supabase.from('inscripciones_equipo');
const tabla = () => supabase.from('tabla_posiciones');
const invitaciones = () => supabase.from('invitaciones_equipo');

export const inscripcionModel = {
  // ---- INSCRIPCIONES ----
  async inscribirEquipo({ torneo_id, equipo_id }) {
    return datos(await inscripciones().insert({ torneo_id, equipo_id }).select().single());
  },
  async buscarPorTorneoYEquipo(torneo_id, equipo_id) {
    return datos(await inscripciones().select('id').eq('torneo_id', torneo_id).eq('equipo_id', equipo_id).limit(1).maybeSingle());
  },
  async contarAceptadas(torneo_id) {
    const { count, error } = await inscripciones().select('id', { count: 'exact', head: true }).eq('torneo_id', torneo_id).eq('estado', 'Aceptado');
    if (error) throw error;
    return count ?? 0;
  },
  async equiposAceptados(torneo_id) {
    return datos(await inscripciones().select('equipo_id').eq('torneo_id', torneo_id).eq('estado', 'Aceptado')).map((i) => i.equipo_id);
  },
  async listarPorTorneo(torneo_id) {
    return datos(await inscripciones().select('id, estado, fecha_inscripcion, equipos ( id, nombre, logo_url )').eq('torneo_id', torneo_id));
  },
  async buscarPorId(id) {
    return datos(await inscripciones().select('*').eq('id', id).maybeSingle());
  },
  async actualizarEstado(id, cambios) {
    return datos(await inscripciones().update(cambios).eq('id', id).select().single());
  },

  // ---- TABLA DE POSICIONES ----
  async asegurarFilaTabla(inscripcion_id) {
    const existe = datos(await tabla().select('inscripcion_id').eq('inscripcion_id', inscripcion_id).limit(1).maybeSingle());
    if (!existe) datos(await tabla().insert({ inscripcion_id }));
  },
  async eliminarFilaTabla(inscripcion_id) {
    datos(await tabla().delete().eq('inscripcion_id', inscripcion_id));
  },
  async obtenerTablaPorTorneo(torneo_id) {
    return datos(await tabla()
      .select('victorias, empates, derrotas, goles_favor, goles_contra, puntos, posicion, inscripciones_equipo!inner ( torneo_id, equipos ( id, nombre, logo_url ) )')
      .eq('inscripciones_equipo.torneo_id', torneo_id));
  },

  // ---- INVITACIONES ----
  async crearInvitacion(invitacion) {
    return datos(await invitaciones().insert(invitacion).select().single());
  },
  async buscarInvitacionPendiente(equipo_id, usuario_id) {
    return datos(await invitaciones().select('id').eq('equipo_id', equipo_id).eq('usuario_id', usuario_id).eq('estado', 'Pendiente').limit(1).maybeSingle());
  },
  async listarInvitacionesPorUsuario(usuario_id) {
    return datos(await invitaciones()
      .select('id, posicion_propuesta, estado, creado_en, equipos ( id, nombre, logo_url )')
      .eq('usuario_id', usuario_id)
      .eq('estado', 'Pendiente'));
  },
  async buscarInvitacionPorId(id) {
    return datos(await invitaciones().select('*').eq('id', id).maybeSingle());
  },
  async actualizarInvitacion(id, cambios) {
    return datos(await invitaciones().update(cambios).eq('id', id).select().single());
  },
};
