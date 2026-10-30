import { supabase } from '../config/supabase.js';
import { datos } from '../utils/helpers.js';
import { SELECT_EVENTO } from './calendario.js';

const eventos = () => supabase.from('eventos_calendario');

// Consultas compartidas por los paneles de cada rol (jugador, entrenador, organizador, árbitro) y por las pantallas de equipo.
export const panelModel = {
  // Eventos cuya columna `campo` está entre `valores`. Opcional: desde/hasta (AAAA-MM-DD), orden y límite.
  async eventosPor(campo, valores, { desde, hasta, ascendente = true, limite = 100 } = {}) {
    if (!valores.length) return [];
    let q = eventos().select(SELECT_EVENTO).in(campo, valores);
    if (desde) q = q.gte('fecha', desde);
    if (hasta) q = q.lte('fecha', hasta);
    return datos(await q.order('fecha', { ascending: ascendente }).order('hora', { ascending: ascendente }).limit(limite));
  },

  // Agrega a cada evento los datos de su torneo (nombre y organizador)
  async conTorneo(lista) {
    const ids = [...new Set(lista.map((e) => e.torneo_id).filter(Boolean))];
    if (!ids.length) return lista;
    const torneos = datos(await supabase.from('torneos').select('id, nombre, organizador_id').in('id', ids));
    const porId = Object.fromEntries(torneos.map((t) => [t.id, t]));
    return lista.map((e) => ({ ...e, torneo: porId[e.torneo_id] ?? null }));
  },

  // Une eventos de varias consultas sin repetir, ordenados por fecha y hora
  unir(...listas) {
    const mapa = new Map();
    listas.flat().forEach((e) => mapa.set(e.id, e));
    return [...mapa.values()].sort((a, b) => `${a.fecha} ${a.hora}`.localeCompare(`${b.fecha} ${b.hora}`));
  },

  // Próximos eventos (desde `desde`) de un conjunto de equipos, donde juegan de local o de visitante
  async proximosDeEquipos(equipoIds, desde, limite = 5) {
    const [local, visitante] = await Promise.all([
      this.eventosPor('equipo_local_id', equipoIds, { desde, limite }),
      this.eventosPor('equipo_visitante_id', equipoIds, { desde, limite }),
    ]);
    return this.conTorneo(this.unir(local, visitante).filter((e) => !['Cancelado', 'Finalizado'].includes(e.estado)).slice(0, limite));
  },

  // Equipos de un entrenador: los que creó y aquellos donde figura como staff
  async equiposDeEntrenador(usuario_id) {
    const [staff, creados] = await Promise.all([
      supabase.from('equipo_staff').select('equipo_id').eq('usuario_id', usuario_id).then(datos),
      supabase.from('equipos').select('id').eq('creado_por', usuario_id).then(datos).catch(() => []), // la columna creado_por puede no existir todavía
    ]);
    const ids = [...new Set([...staff.map((s) => s.equipo_id), ...creados.map((c) => c.id)])];
    if (!ids.length) return [];
    return datos(await supabase.from('equipos').select('id, nombre, logo_url, creado_por').in('id', ids).order('nombre'));
  },

  // Equipos donde juega un jugador, con su posición y dorsal
  async equiposDeJugador(usuario_id) {
    const filas = datos(await supabase
      .from('equipo_jugadores')
      .select('posicion, dorsal, es_titular, estado_convocatoria, equipos ( id, nombre, logo_url )')
      .eq('usuario_id', usuario_id));
    return filas.filter((f) => f.equipos).map((f) => ({
      ...f.equipos, posicion: f.posicion, dorsal: f.dorsal, es_titular: f.es_titular, estado_convocatoria: f.estado_convocatoria,
    }));
  },

  // Cantidad de jugadores por equipo: { equipo_id: n }
  async contarJugadores(equipoIds) {
    if (!equipoIds.length) return {};
    const filas = datos(await supabase.from('equipo_jugadores').select('equipo_id').in('equipo_id', equipoIds));
    return filas.reduce((acc, f) => ({ ...acc, [f.equipo_id]: (acc[f.equipo_id] ?? 0) + 1 }), {});
  },
};

export const suma = (filas, campo) => filas.reduce((a, f) => a + (Number(f[campo]) || 0), 0);
