import { supabase } from '../config/supabase.js';
import { datos } from '../utils/helpers.js';

const notificaciones = () => supabase.from('notificaciones');

// Si todavía no se ejecutó backend/sql/003_notificaciones_ampliado.sql, se guarda solo el texto
const faltanColumnas = (e) => /tipo|referencia_id|schema cache/i.test(e?.message ?? '');
const sinExtras = ({ tipo, referencia_id, ...basica }) => basica; // eslint-disable-line no-unused-vars

export const notificacionModel = {
  async crear(notificacion) {
    try {
      return datos(await notificaciones().insert(notificacion).select().single());
    } catch (e) {
      if (!faltanColumnas(e)) throw e;
      return datos(await notificaciones().insert(sinExtras(notificacion)).select().single());
    }
  },
  // Inserta varias de una vez (mismo texto para varios destinatarios)
  async crearVarias(filas) {
    if (!filas.length) return [];
    try {
      return datos(await notificaciones().insert(filas).select());
    } catch (e) {
      if (!faltanColumnas(e)) throw e;
      return datos(await notificaciones().insert(filas.map(sinExtras)).select());
    }
  },
  async listarPorUsuario(usuario_id, { limite = 100, soloNoLeidas = false } = {}) {
    let q = notificaciones().select('*').eq('usuario_id', usuario_id).order('creado_en', { ascending: false }).limit(limite);
    if (soloNoLeidas) q = q.eq('leida', false);
    return datos(await q);
  },
  async contarNoLeidas(usuario_id) {
    const { count, error } = await notificaciones().select('id', { count: 'exact', head: true }).eq('usuario_id', usuario_id).eq('leida', false);
    if (error) throw error;
    return count ?? 0;
  },
  // Solo si la notificación es del usuario
  async marcarLeida(id, usuario_id) {
    return datos(await notificaciones().update({ leida: true }).eq('id', id).eq('usuario_id', usuario_id).select().maybeSingle());
  },
  async marcarTodasLeidas(usuario_id) {
    datos(await notificaciones().update({ leida: true }).eq('usuario_id', usuario_id).eq('leida', false));
  },
  // Devuelve true si existía y era del usuario
  async eliminar(id, usuario_id) {
    const filas = datos(await notificaciones().delete().eq('id', id).eq('usuario_id', usuario_id).select('id'));
    return filas.length > 0;
  },
};

// Las notificaciones son accesorias: si fallan no deben romper la acción principal.
// opciones: { tipo, referencia_id }
export const notificar = (usuario_id, titulo, { tipo, referencia_id } = {}) =>
  notificacionModel
    .crear({ usuario_id, titulo, ...(tipo && { tipo }), ...(referencia_id != null && { referencia_id: String(referencia_id) }) })
    .catch((e) => console.error('No se pudo crear la notificación:', e.message));

// Mismo aviso para varias personas (sin repetir destinatarios)
export const notificarVarios = (usuarioIds, titulo, { tipo, referencia_id } = {}) => {
  const unicos = [...new Set(usuarioIds.filter(Boolean).map(String))];
  return notificacionModel
    .crearVarias(unicos.map((usuario_id) => ({ usuario_id, titulo, ...(tipo && { tipo }), ...(referencia_id != null && { referencia_id: String(referencia_id) }) })))
    .catch((e) => console.error('No se pudieron crear las notificaciones:', e.message));
};

// Todas las personas vinculadas a unos equipos: jugadores, cuerpo técnico y quien creó el equipo
export const destinatariosDeEquipos = async (equipoIds) => {
  const ids = equipoIds.filter(Boolean);
  if (!ids.length) return [];
  const [jugadores, staff, duenos] = await Promise.all([
    supabase.from('equipo_jugadores').select('usuario_id').in('equipo_id', ids).then(datos),
    supabase.from('equipo_staff').select('usuario_id').in('equipo_id', ids).then(datos),
    supabase.from('equipos').select('creado_por').in('id', ids).then(datos).catch(() => []), // la columna creado_por puede no existir
  ]);
  return [...new Set([...jugadores.map((j) => j.usuario_id), ...staff.map((s) => s.usuario_id), ...duenos.map((d) => d.creado_por)].filter(Boolean).map(String))];
};