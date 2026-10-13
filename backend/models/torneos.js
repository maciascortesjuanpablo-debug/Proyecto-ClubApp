import { supabase } from '../config/supabase.js';
import { datos } from '../utils/helpers.js';

const torneos = () => supabase.from('torneos');
const RELACIONES = 'deportes ( id, nombre ), formatos ( id, nombre ), usuarios ( id, nombre, apellido )';

export const torneoModel = {
  async crear(torneo) {
    return datos(await torneos().insert(torneo).select().single());
  },
  async listarTodos() {
    return datos(await torneos()
      .select(`id, nombre, max_equipos, estado, jornada_actual, jornada_total, ciudad, creado_en, ${RELACIONES}`)
      .order('creado_en', { ascending: false }));
  },
  async buscarPorId(id) {
    return datos(await torneos().select(`*, ${RELACIONES}`).eq('id', id).maybeSingle());
  },
  async listarPorOrganizador(organizador_id) {
    return datos(await torneos().select('*').eq('organizador_id', organizador_id).order('creado_en', { ascending: false }));
  },
  async actualizar(id, cambios) {
    return datos(await torneos().update(cambios).eq('id', id).select().single());
  },
  async eliminar(id) {
    datos(await torneos().delete().eq('id', id));
  },

  // ---- GRUPOS DEL TORNEO ----
  async crearGrupo({ torneo_id, nombre }) {
    return datos(await supabase.from('grupos_torneo').insert({ torneo_id, nombre }).select().single());
  },
  async listarGruposPorTorneo(torneo_id) {
    return datos(await supabase.from('grupos_torneo').select('*').eq('torneo_id', torneo_id).order('nombre'));
  },
};
