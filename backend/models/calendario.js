import { supabase } from '../config/supabase.js';
import { datos } from '../utils/helpers.js';

const eventos = () => supabase.from('eventos_calendario');
const SELECT_EVENTO = `*, sedes_canchas(id, nombre, direccion, ciudad),
  equipo_local:equipo_local_id(id, nombre, logo_url),
  equipo_visitante:equipo_visitante_id(id, nombre, logo_url)`;

export const calendarioModel = {
  // SEDES
  async crearSede(sede) {
    return datos(await supabase.from('sedes_canchas').insert(sede).select().single());
  },
  async listarSedes() {
    return datos(await supabase.from('sedes_canchas').select('*').order('nombre'));
  },

  // EVENTOS
  async crearEvento(evento) {
    return datos(await eventos().insert(evento).select().single());
  },
  async listarPorTorneo(torneo_id) {
    return datos(await eventos().select(SELECT_EVENTO).eq('torneo_id', torneo_id).order('fecha', { ascending: true }));
  },
  async buscarPorId(id) {
    return datos(await eventos().select(SELECT_EVENTO).eq('id', id).maybeSingle());
  },
  async actualizar(id, cambios) {
    return datos(await eventos().update(cambios).eq('id', id).select().single());
  },
  async eliminar(id) {
    datos(await eventos().delete().eq('id', id));
  },

  // ÁRBITROS
  async asignarArbitro(arbitro) {
    return datos(await supabase.from('partido_arbitros').insert(arbitro).select().single());
  },
  async listarArbitrosPorEvento(evento_id) {
    return datos(await supabase.from('partido_arbitros').select('id, rol_arbitraje, usuarios(id, nombre, apellido)').eq('evento_id', evento_id));
  },
  async esArbitroDelEvento(evento_id, usuario_id) {
    return !!datos(await supabase.from('partido_arbitros').select('id').eq('evento_id', evento_id).eq('usuario_id', usuario_id).limit(1).maybeSingle());
  },
};
