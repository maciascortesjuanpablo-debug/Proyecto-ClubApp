import { supabase } from '../config/supabase.js';
import { datos } from './helpers.js';
import { destinatariosDeEquipos, notificarVarios } from '../models/notificaciones.js';

// Avisos automáticos de partidos. Nunca rompen la acción principal: si algo falla, solo se registra en consola.
// Se llaman SIN await desde los controladores para no hacer esperar la respuesta.

const MESES = ['ene', 'feb', 'mar', 'abr', 'may', 'jun', 'jul', 'ago', 'sep', 'oct', 'nov', 'dic'];
const dia = (f) => String(f).split('T')[0];
const cuando = (fecha, hora) => {
  const [, m, d] = dia(fecha).split('-');
  return `${Number(d)} ${MESES[Number(m) - 1]} · ${String(hora).slice(0, 5)}`;
};

const seguro = (fn) => async (...args) => {
  try {
    await fn(...args);
  } catch (e) {
    console.error('No se pudo enviar el aviso:', e.message);
  }
};

// "Halcones vs Tigres"
const enfrentamiento = async (evento) => {
  const ids = [evento.equipo_local_id, evento.equipo_visitante_id].filter(Boolean);
  const equipos = ids.length ? datos(await supabase.from('equipos').select('id, nombre').in('id', ids)) : [];
  const nombre = (id) => equipos.find((e) => String(e.id) === String(id))?.nombre ?? 'Por definir';
  return { local: nombre(evento.equipo_local_id), visitante: nombre(evento.equipo_visitante_id) };
};

const arbitrosDe = async (evento_id) => datos(await supabase.from('partido_arbitros').select('usuario_id').eq('evento_id', evento_id)).map((a) => a.usuario_id);

const sinActor = (ids, actorId) => ids.filter((id) => String(id) !== String(actorId));

// Un partido nuevo: avisa a los equipos
export const avisarPartidoProgramado = seguro(async (evento, actorId) => {
  if (evento.tipo !== 'Partido') return;
  const { local, visitante } = await enfrentamiento(evento);
  const personas = await destinatariosDeEquipos([evento.equipo_local_id, evento.equipo_visitante_id]);
  await notificarVarios(sinActor(personas, actorId), `Nuevo partido: ${local} vs ${visitante} · ${cuando(evento.fecha, evento.hora)}`, { tipo: 'partido', referencia_id: evento.id });
});

// Cambios en un partido: cancelado, aplazado, reprogramado, en vivo o con resultado final
export const avisarCambioPartido = seguro(async (antes, despues, actorId) => {
  if (despues.tipo !== 'Partido') return;
  const { local, visitante } = await enfrentamiento(despues);
  const vs = `${local} vs ${visitante}`;

  const cambioEstado = antes.estado !== despues.estado;
  const movido = dia(antes.fecha) !== dia(despues.fecha) || String(antes.hora).slice(0, 5) !== String(despues.hora).slice(0, 5);
  const marcador = despues.resultado_local != null && despues.resultado_visitante != null;
  const marcadorCambio = antes.resultado_local !== despues.resultado_local || antes.resultado_visitante !== despues.resultado_visitante;

  let titulo;
  let tipo = 'partido';
  let incluirOrganizador = false;
  if (despues.estado === 'Finalizado' && marcador && (cambioEstado || marcadorCambio)) {
    titulo = `Resultado final: ${local} ${despues.resultado_local} - ${despues.resultado_visitante} ${visitante}`;
    tipo = 'resultado';
    incluirOrganizador = true;
  } else if (cambioEstado && despues.estado === 'Cancelado') titulo = `Partido cancelado: ${vs}`;
  else if (cambioEstado && despues.estado === 'Aplazado') titulo = `Partido aplazado: ${vs}`;
  else if (cambioEstado && despues.estado === 'En vivo') titulo = `Comenzó el partido: ${vs}`;
  else if (movido) titulo = `Partido reprogramado: ${vs} · ${cuando(despues.fecha, despues.hora)}`;
  else return; // otros cambios (sede, etc.) no merecen aviso

  const equipos = [antes.equipo_local_id, antes.equipo_visitante_id, despues.equipo_local_id, despues.equipo_visitante_id];
  const [personas, arbitros] = await Promise.all([destinatariosDeEquipos(equipos), arbitrosDe(despues.id)]);
  let extra = [];
  if (incluirOrganizador) {
    const torneo = datos(await supabase.from('torneos').select('organizador_id').eq('id', despues.torneo_id).maybeSingle());
    extra = torneo?.organizador_id ? [torneo.organizador_id] : [];
  }
  await notificarVarios(sinActor([...personas, ...arbitros, ...extra], actorId), titulo, { tipo, referencia_id: despues.id });
});

// Un árbitro es asignado a un partido
export const avisarArbitro = seguro(async (evento, usuario_id, rol, actorId) => {
  if (String(usuario_id) === String(actorId)) return;
  const { local, visitante } = await enfrentamiento(evento);
  await notificarVarios([usuario_id], `Te asignaron como árbitro ${String(rol).toLowerCase()}: ${local} vs ${visitante} · ${cuando(evento.fecha, evento.hora)}`, { tipo: 'designacion', referencia_id: evento.id });
});