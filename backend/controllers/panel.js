import { supabase } from '../config/supabase.js';
import { panelModel, suma } from '../models/panel.js';
import { perfilJugadorModel } from '../models/perfil_jugador.js';
import { estadisticaModel } from '../models/estadisticas.js';
import { inscripcionModel } from '../models/inscripciones.js';
import { torneoModel } from '../models/torneos.js';
import { ahora, datos, fallo } from '../utils/helpers.js';

// Paneles de inicio de cada rol. Cada uno devuelve SOLO lo que ese rol necesita:
// un árbitro no recibe estadísticas de jugador, un jugador no recibe datos de gestión, etc.
// El control de acceso por rol está en routes/panel.js.

/* ---------- JUGADOR ---------- */
export const panelJugador = async (req, res) => {
  try {
    const uid = req.usuario.id;
    const hoy = ahora().fecha;
    const [perfil, equipos, stats, invitaciones] = await Promise.all([
      perfilJugadorModel.buscarPorUsuarioId(uid),
      panelModel.equiposDeJugador(uid),
      estadisticaModel.listarPorJugador(uid),
      inscripcionModel.listarInvitacionesPorUsuario(uid),
    ]);
    const proximos = await panelModel.proximosDeEquipos(equipos.map((e) => e.id), hoy, 5);

    // Una fila por partido jugado; la serie va de más antiguo a más reciente para dibujarla en un gráfico
    const serie = [...stats]
      .sort((a, b) => String(a.eventos_calendario?.fecha ?? '').localeCompare(String(b.eventos_calendario?.fecha ?? '')))
      .slice(-8)
      .map((s) => ({ fecha: s.eventos_calendario?.fecha ?? null, goles: s.goles, asistencias: s.asistencias, tarjetas_amarillas: s.tarjetas_amarillas, tarjetas_rojas: s.tarjetas_rojas, minutos_jugados: s.minutos_jugados }));

    res.json({
      perfil,
      equipos,
      proximosPartidos: proximos,
      estadisticas: {
        partidos: stats.length,
        goles: suma(stats, 'goles'),
        asistencias: suma(stats, 'asistencias'),
        tarjetas_amarillas: suma(stats, 'tarjetas_amarillas'),
        tarjetas_rojas: suma(stats, 'tarjetas_rojas'),
        minutos: suma(stats, 'minutos_jugados'),
      },
      ultimosPartidos: serie,
      invitaciones,
    });
  } catch (error) {
    fallo(res, error, 'Error al cargar el panel del jugador');
  }
};

/* ---------- ENTRENADOR ---------- */
export const panelEntrenador = async (req, res) => {
  try {
    const uid = req.usuario.id;
    const hoy = ahora().fecha;
    const equipos = await panelModel.equiposDeEntrenador(uid);
    const ids = equipos.map((e) => e.id);

    const [conteo, inscripciones, proximos, invitaciones] = await Promise.all([
      panelModel.contarJugadores(ids),
      ids.length ? supabase.from('inscripciones_equipo').select('id, estado, equipo_id, torneo_id').in('equipo_id', ids).then(datos) : [],
      panelModel.proximosDeEquipos(ids, hoy, 5),
      supabase.from('invitaciones_equipo').select('id', { count: 'exact', head: true }).eq('invitado_por', uid).eq('estado', 'Pendiente').then(({ count }) => count ?? 0),
    ]);

    const torneoIds = [...new Set(inscripciones.map((i) => i.torneo_id))];
    const torneos = torneoIds.length ? datos(await supabase.from('torneos').select('id, nombre, estado').in('id', torneoIds)) : [];
    const torneoPorId = Object.fromEntries(torneos.map((t) => [t.id, t]));

    const salida = equipos.map((e) => ({
      ...e,
      jugadores: conteo[e.id] ?? 0,
      inscripciones: inscripciones.filter((i) => String(i.equipo_id) === String(e.id)).map((i) => ({ id: i.id, estado: i.estado, torneo: torneoPorId[i.torneo_id] ?? null })),
    }));

    res.json({
      equipos: salida,
      proximosPartidos: proximos,
      invitacionesPendientes: invitaciones,
      totales: {
        equipos: salida.length,
        jugadores: salida.reduce((a, e) => a + e.jugadores, 0),
        torneosActivos: new Set(inscripciones.filter((i) => i.estado === 'Aceptado' && torneoPorId[i.torneo_id]?.estado !== 'Finalizado').map((i) => i.torneo_id)).size,
        inscripcionesPendientes: inscripciones.filter((i) => i.estado === 'Pendiente').length,
      },
    });
  } catch (error) {
    fallo(res, error, 'Error al cargar el panel del entrenador');
  }
};

/* ---------- ORGANIZADOR ---------- */
export const panelOrganizador = async (req, res) => {
  try {
    const uid = req.usuario.id;
    const { fecha: hoy } = ahora();
    const torneos = await torneoModel.listarPorOrganizador(uid);
    const ids = torneos.map((t) => t.id);

    const [inscripciones, partidos, proximos, pendientes] = await Promise.all([
      ids.length ? supabase.from('inscripciones_equipo').select('id, estado, torneo_id').in('torneo_id', ids).then(datos) : [],
      ids.length ? supabase.from('eventos_calendario').select('id, torneo_id, tipo, estado, fecha').in('torneo_id', ids).limit(5000).then(datos) : [],
      panelModel.eventosPor('torneo_id', ids, { desde: hoy, limite: 40 }),
      ids.length
        ? supabase.from('inscripciones_equipo').select('id, estado, fecha_inscripcion, torneo_id, equipos ( id, nombre, logo_url )').in('torneo_id', ids).eq('estado', 'Pendiente').limit(10).then(datos)
        : [],
    ]);

    // Partidos por jugar que todavía no tienen árbitro
    const porJugar = proximos.filter((e) => e.tipo === 'Partido' && e.estado === 'Programado');
    const conArbitro = porJugar.length ? datos(await supabase.from('partido_arbitros').select('evento_id').in('evento_id', porJugar.map((e) => e.id))) : [];
    const idsConArbitro = new Set(conArbitro.map((a) => String(a.evento_id)));
    const sinArbitro = porJugar.filter((e) => !idsConArbitro.has(String(e.id))).length;

    const hasta7 = new Date(`${hoy}T00:00:00`);
    hasta7.setDate(hasta7.getDate() + 7);
    const limiteSemana = `${hasta7.getFullYear()}-${String(hasta7.getMonth() + 1).padStart(2, '0')}-${String(hasta7.getDate()).padStart(2, '0')}`;

    const torneoPorId = Object.fromEntries(torneos.map((t) => [String(t.id), { id: t.id, nombre: t.nombre }]));
    const resumen = torneos.map((t) => {
      const ins = inscripciones.filter((i) => String(i.torneo_id) === String(t.id));
      const par = partidos.filter((p) => String(p.torneo_id) === String(t.id) && p.tipo === 'Partido');
      return {
        id: t.id, nombre: t.nombre, estado: t.estado, max_equipos: t.max_equipos, jornada_actual: t.jornada_actual, jornada_total: t.jornada_total, ciudad: t.ciudad,
        equipos_aceptados: ins.filter((i) => i.estado === 'Aceptado').length,
        equipos_pendientes: ins.filter((i) => i.estado === 'Pendiente').length,
        partidos_total: par.length,
        partidos_jugados: par.filter((p) => p.estado === 'Finalizado').length,
      };
    });

    res.json({
      torneos: resumen,
      inscripcionesPendientes: pendientes.map((i) => ({ ...i, torneo: torneoPorId[String(i.torneo_id)] ?? null })),
      proximosPartidos: await panelModel.conTorneo(proximos.filter((e) => e.estado !== 'Cancelado').slice(0, 5)),
      sinArbitro,
      totales: {
        torneos: torneos.length,
        equipos: resumen.reduce((a, t) => a + t.equipos_aceptados, 0),
        partidosHoy: partidos.filter((p) => p.tipo === 'Partido' && String(p.fecha).slice(0, 10) === hoy).length,
        partidosSemana: partidos.filter((p) => p.tipo === 'Partido' && String(p.fecha).slice(0, 10) >= hoy && String(p.fecha).slice(0, 10) <= limiteSemana).length,
      },
    });
  } catch (error) {
    fallo(res, error, 'Error al cargar el panel del organizador');
  }
};

/* ---------- ÁRBITRO ---------- */
export const panelArbitro = async (req, res) => {
  try {
    const uid = req.usuario.id;
    const { fecha: hoy } = ahora();
    const asignaciones = datos(await supabase.from('partido_arbitros').select('evento_id, rol_arbitraje').eq('usuario_id', uid));
    const ids = asignaciones.map((a) => a.evento_id);
    const rolPorEvento = Object.fromEntries(asignaciones.map((a) => [String(a.evento_id), a.rol_arbitraje]));

    const todos = await panelModel.conTorneo(await panelModel.eventosPor('id', ids, { limite: 500 }));
    const marcar = (e) => ({ ...e, rol_arbitraje: rolPorEvento[String(e.id)] ?? 'Principal' });
    const dia = (e) => String(e.fecha).slice(0, 10);

    const finalizados = todos.filter((e) => e.estado === 'Finalizado');
    const pendientes = todos.filter((e) => !['Finalizado', 'Cancelado'].includes(e.estado));
    const hoyLista = pendientes.filter((e) => dia(e) === hoy);
    const proximos = pendientes.filter((e) => dia(e) > hoy).slice(0, 10);
    const recientes = todos.filter((e) => e.estado === 'Finalizado' || (dia(e) < hoy && e.estado !== 'Cancelado')).reverse().slice(0, 10);

    // Lo que ocurrió en los partidos que dirigió (no son estadísticas suyas, son del partido)
    const idsFinalizados = finalizados.map((e) => e.id);
    const filas = idsFinalizados.length ? datos(await supabase.from('estadisticas_jugador').select('goles, tarjetas_amarillas, tarjetas_rojas').in('evento_id', idsFinalizados)) : [];

    const torneoIds = [...new Set(todos.map((e) => e.torneo_id).filter(Boolean))];
    res.json({
      hoy: hoyLista.map(marcar),
      proximos: proximos.map(marcar),
      recientes: recientes.map(marcar),
      totales: {
        asignados: ids.length,
        dirigidos: finalizados.length,
        proximos: pendientes.filter((e) => dia(e) >= hoy).length,
        tarjetas_amarillas: suma(filas, 'tarjetas_amarillas'),
        tarjetas_rojas: suma(filas, 'tarjetas_rojas'),
        goles: suma(filas, 'goles') || finalizados.reduce((a, e) => a + (e.resultado_local ?? 0) + (e.resultado_visitante ?? 0), 0),
      },
      torneos: todos.filter((e) => e.torneo).filter((e, i, arr) => arr.findIndex((x) => x.torneo_id === e.torneo_id) === i).map((e) => ({ id: e.torneo.id, nombre: e.torneo.nombre })).filter((t) => torneoIds.includes(t.id)),
    });
  } catch (error) {
    fallo(res, error, 'Error al cargar el panel del árbitro');
  }
};
