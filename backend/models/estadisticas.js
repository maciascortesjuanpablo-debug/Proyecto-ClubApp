import { supabase } from '../config/supabase.js';
import { datos } from '../utils/helpers.js';

const estadisticas = () => supabase.from('estadisticas_jugador');
const CAMPOS = 'id, goles, asistencias, tarjetas_amarillas, tarjetas_rojas, minutos_jugados';

export const estadisticaModel = {
  async crear(estadistica) {
    return datos(await estadisticas().insert(estadistica).select().single());
  },
  async buscarPorId(id) {
    return datos(await estadisticas().select('*').eq('id', id).maybeSingle());
  },
  async listarPorEvento(evento_id) {
    return datos(await estadisticas().select(`${CAMPOS}, usuarios(id, nombre, apellido), equipos(id, nombre)`).eq('evento_id', evento_id));
  },
  async listarPorJugador(usuario_id) {
    return datos(await estadisticas()
      .select(`${CAMPOS}, creado_en, eventos_calendario(id, fecha, torneo_id)`)
      .eq('usuario_id', usuario_id)
      .order('creado_en', { ascending: false }));
  },
  async actualizar(id, cambios) {
    return datos(await estadisticas().update(cambios).eq('id', id).select().single());
  },
  async eliminar(id) {
    datos(await estadisticas().delete().eq('id', id));
  },
};
