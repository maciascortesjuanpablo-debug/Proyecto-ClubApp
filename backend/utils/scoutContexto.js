import { supabase } from '../config/supabase.js';
import { panelModel } from '../models/panel.js';
import { torneoModel } from '../models/torneos.js';
import { inscripcionModel } from '../models/inscripciones.js';
import { ROLES, ahora, datos } from './helpers.js';

export const NOMBRE_ROL = { 1: 'Usuario (cuenta sin rol definido)', 2: 'Jugador', 3: 'Entrenador', 4: 'Organizador', 5: 'Árbitro', 6: 'Administrador' };

// Datos de la base dentro del prompt: sin saltos de línea para que no parezcan instrucciones
const limpiar = (s) => String(s ?? '').replace(/[\r\n]+/g, ' ').slice(0, 60);
const MESES = ['ene', 'feb', 'mar', 'abr', 'may', 'jun', 'jul', 'ago', 'sep', 'oct', 'nov', 'dic'];
const cuando = (fecha, hora) => {
  const [, m, d] = String(fecha).split('T')[0].split('-');
  return `${Number(d)} ${MESES[Number(m) - 1]} ${String(hora).slice(0, 5)}`;
};
const partido = (e) => `- ${limpiar(e.equipo_local?.nombre ?? 'Por definir')} vs ${limpiar(e.equipo_visitante?.nombre ?? 'Por definir')} | ${cuando(e.fecha, e.hora)}${e.torneo?.nombre ? ` | ${limpiar(e.torneo.nombre)}` : ''} | ${e.estado}`;

// Un fallo al leer una parte no debe tumbar el chat: se omite esa parte
const seguro = async (fn, vacio = '') => {
  try {
    return await fn();
  } catch (e) {
    console.error('Scout AI: contexto incompleto:', e.message);
    return vacio;
  }
};

const seccionEntrenador = async (uid, hoy) => {
  const equipos = await panelModel.equiposDeEntrenador(uid);
  if (!equipos.length) return 'Todavía no ha creado equipos.';
  const ids = equipos.map((e) => e.id);
  const [conteo, inscripciones, proximos] = await Promise.all([
    panelModel.contarJugadores(ids),
    supabase.from('inscripciones_equipo').select('equipo_id, estado, torneo_id').in('equipo_id', ids).then(datos),
    panelModel.proximosDeEquipos(ids, hoy, 4),
  ]);
  const torneoIds = [...new Set(inscripciones.map((i) => i.torneo_id))];
  const torneos = torneoIds.length ? datos(await supabase.from('torneos').select('id, nombre').in('id', torneoIds)) : [];
  const nombreTorneo = Object.fromEntries(torneos.map((t) => [String(t.id), t.nombre]));
  const lineas = equipos.map((e) => {
    const t = inscripciones.filter((i) => String(i.equipo_id) === String(e.id)).map((i) => `${limpiar(nombreTorneo[String(i.torneo_id)])} (${i.estado})`).join(', ') || 'ninguno';
    return `- ${limpiar(e.nombre)} | ${e.formato ?? 'formato sin definir'} | formación ${e.formacion ?? 'sin definir'} | jugadores ${conteo[e.id] ?? 0}${e.max_jugadores ? `/${e.max_jugadores}` : ''} | torneos: ${t}`;
  });
  return `Sus equipos:\n${lineas.join('\n')}\nSus próximos partidos:\n${proximos.length ? proximos.map(partido).join('\n') : 'Ninguno programado.'}`;
};

const seccionJugador = async (uid, hoy) => {
  const [equipos, invitaciones] = await Promise.all([panelModel.equiposDeJugador(uid), inscripcionModel.listarInvitacionesPorUsuario(uid)]);
  const pendientes = invitaciones.filter((i) => !i.estado || i.estado === 'Pendiente').length;
  if (!equipos.length) return `Todavía no pertenece a ningún equipo. Invitaciones pendientes: ${pendientes}.`;
  const proximos = await panelModel.proximosDeEquipos(equipos.map((e) => e.id), hoy, 4);
  const lineas = equipos.map((e) => `- ${limpiar(e.nombre)} | posición ${limpiar(e.posicion)} | dorsal ${e.dorsal ?? 'sin asignar'} | ${e.es_titular ? 'titular' : 'suplente'}`);
  return `Sus equipos:\n${lineas.join('\n')}\nInvitaciones pendientes: ${pendientes}.\nSus próximos partidos:\n${proximos.length ? proximos.map(partido).join('\n') : 'Ninguno programado.'}`;
};

const seccionOrganizador = async (uid, hoy) => {
  const torneos = await torneoModel.listarPorOrganizador(uid);
  if (!torneos.length) return 'Todavía no ha creado torneos.';
  const ids = torneos.map((t) => t.id);
  const [inscripciones, proximos] = await Promise.all([
    supabase.from('inscripciones_equipo').select('torneo_id, estado').in('torneo_id', ids).then(datos),
    panelModel.eventosPor('torneo_id', ids, { desde: hoy, limite: 6 }).then((l) => panelModel.conTorneo(l.filter((e) => e.estado !== 'Cancelado').slice(0, 4))),
  ]);
  const lineas = torneos.map((t) => {
    const mias = inscripciones.filter((i) => String(i.torneo_id) === String(t.id));
    return `- ${limpiar(t.nombre)} | estado ${limpiar(t.estado)} | equipos aceptados ${mias.filter((i) => i.estado === 'Aceptado').length}/${t.max_equipos ?? '?'} | solicitudes pendientes ${mias.filter((i) => i.estado === 'Pendiente').length}`;
  });
  return `Sus torneos:\n${lineas.join('\n')}\nPróximos partidos de sus torneos:\n${proximos.length ? proximos.map(partido).join('\n') : 'Ninguno programado.'}`;
};

const seccionArbitro = async (uid, hoy) => {
  const asignaciones = datos(await supabase.from('partido_arbitros').select('evento_id, rol_arbitraje').eq('usuario_id', uid));
  if (!asignaciones.length) return 'Todavía no tiene partidos asignados.';
  const eventos = await panelModel.eventosPor('id', asignaciones.map((a) => a.evento_id), { desde: hoy, limite: 6 });
  const pendientes = (await panelModel.conTorneo(eventos.filter((e) => !['Finalizado', 'Cancelado'].includes(e.estado)))).slice(0, 5);
  return `Total de partidos asignados: ${asignaciones.length}.\nSus próximos partidos por dirigir:\n${pendientes.length ? pendientes.map(partido).join('\n') : 'Ninguno por dirigir.'}`;
};

/**
 * Datos reales que Scout AI puede usar: quién es la persona, lo suyo (equipos, torneos, partidos según su rol)
 * y las listas públicas de torneos y equipos. La lista de jugadores solo se entrega a quien la necesita para ojear (se recibe ya filtrada).
 */
export const construirContexto = async (usuario, { jugadores = null } = {}) => {
  const hoy = ahora().fecha;
  const rol = usuario.rol_id;

  const [persona, suyo, torneos, equipos] = await Promise.all([
    seguro(async () => datos(await supabase.from('usuarios').select('nombre, apellido').eq('id', usuario.id).maybeSingle()), null),
    seguro(() => {
      if (rol === ROLES.ENTRENADOR) return seccionEntrenador(usuario.id, hoy);
      if (rol === ROLES.JUGADOR) return seccionJugador(usuario.id, hoy);
      if (rol === ROLES.ORGANIZADOR) return seccionOrganizador(usuario.id, hoy);
      if (rol === ROLES.ARBITRO) return seccionArbitro(usuario.id, hoy);
      if (rol === ROLES.ADMIN) return 'Tiene acceso al panel de administración (usuarios, torneos, equipos e inscripciones).';
      return 'Cuenta sin rol definido: solo puede consultar.';
    }),
    seguro(async () => datos(await supabase.from('torneos').select('id, nombre, estado, ciudad, max_equipos, deportes ( nombre )').order('creado_en', { ascending: false }).limit(20)), []),
    seguro(async () => datos(await supabase.from('equipos').select('nombre, ciudad, formato').order('creado_en', { ascending: false }).limit(30)), []),
  ]);

  const nombre = persona ? limpiar(`${persona.nombre} ${persona.apellido}`) : 'Persona';
  const listaTorneos = torneos.map((t) => `- ${limpiar(t.nombre)} | ${limpiar(t.deportes?.nombre)} | estado ${limpiar(t.estado)} | ciudad ${limpiar(t.ciudad)} | máx. ${t.max_equipos ?? '?'} equipos`).join('\n') || 'No hay torneos registrados todavía.';
  const listaEquipos = equipos.map((e) => `- ${limpiar(e.nombre)}${e.ciudad ? ` | ${limpiar(e.ciudad)}` : ''}${e.formato ? ` | ${e.formato}` : ''}`).join('\n') || 'No hay equipos registrados todavía.';
  const listaJugadores = jugadores === null
    ? 'Esta información no está disponible para el rol de esta persona.'
    : jugadores.map((j) => `- ${j.nombre} | Posición: ${j.posicion} | Edad: ${j.edad} | Equipo: ${j.equipo}`).join('\n') || 'No hay jugadores registrados todavía.';

  return {
    perfil: `${nombre} | rol: ${NOMBRE_ROL[rol] ?? 'Usuario'}`,
    datos: `LO SUYO (según su rol):\n${suyo || 'Sin datos.'}\n\nTORNEOS REGISTRADOS:\n${listaTorneos}\n\nEQUIPOS REGISTRADOS:\n${listaEquipos}\n\nJUGADORES (para ojear, solo entrenadores, organizadores y administradores):\n${listaJugadores}`,
  };
};