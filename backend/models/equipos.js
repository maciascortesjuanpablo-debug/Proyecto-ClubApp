import { supabase } from '../config/supabase.js';
import { datos } from '../utils/helpers.js';

const equipos = () => supabase.from('equipos');
const jugadores = () => supabase.from('equipo_jugadores');
const staff = () => supabase.from('equipo_staff');

export const equipoModel = {
  async crear(equipo) {
    return datos(await equipos().insert(equipo).select().single());
  },
  async listarTodos() {
    return datos(await equipos().select('*').order('creado_en', { ascending: false }));
  },
  async buscarPorId(id) {
    return datos(await equipos().select('*').eq('id', id).maybeSingle());
  },
  async actualizar(id, cambios) {
    return datos(await equipos().update(cambios).eq('id', id).select().single());
  },
  async eliminar(id) {
    datos(await equipos().delete().eq('id', id));
  },

  // ---- JUGADORES DEL EQUIPO ----
  async agregarJugador(jugador) {
    return datos(await jugadores().insert(jugador).select().single());
  },
  async buscarJugador(equipo_id, usuario_id) {
    return datos(await jugadores().select('id').eq('equipo_id', equipo_id).eq('usuario_id', usuario_id).maybeSingle());
  },
  async listarJugadores(equipo_id) {
    return datos(await jugadores()
      .select('id, posicion, dorsal, estado_convocatoria, es_titular, creado_en, usuarios ( id, nombre, apellido )')
      .eq('equipo_id', equipo_id));
  },
  async actualizarJugador(equipo_id, usuario_id, cambios) {
    return datos(await jugadores().update(cambios).eq('equipo_id', equipo_id).eq('usuario_id', usuario_id).select().single());
  },
  async eliminarJugador(equipo_id, usuario_id) {
    datos(await jugadores().delete().eq('equipo_id', equipo_id).eq('usuario_id', usuario_id));
  },

  // ---- STAFF DEL EQUIPO ----
  async agregarStaff(miembro) {
    return datos(await staff().insert(miembro).select().single());
  },
  async listarStaff(equipo_id) {
    return datos(await staff().select('id, cargo, creado_en, usuarios ( id, nombre, apellido )').eq('equipo_id', equipo_id));
  },
  async eliminarStaff(equipo_id, usuario_id) {
    datos(await staff().delete().eq('equipo_id', equipo_id).eq('usuario_id', usuario_id));
  },
};
