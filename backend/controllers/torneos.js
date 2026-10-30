import { supabase } from '../config/supabase.js';
import { torneoModel } from '../models/torneos.js';
import { inscripcionModel } from '../models/inscripciones.js';
import { panelModel } from '../models/panel.js';
import { ahora, datos, entero, fallo, pick, texto } from '../utils/helpers.js';
import { esOrganizadorTorneo } from '../utils/permisos.js';

// Middleware: carga el torneo de :id y exige que el usuario sea su organizador (o Admin)
export const torneoPropio = async (req, res, next) => {
  try {
    const torneo = await torneoModel.buscarPorId(req.params.id);
    if (!torneo) return res.status(404).json({ mensaje: 'Torneo no encontrado' });
    if (!esOrganizadorTorneo(req, torneo)) return res.status(403).json({ mensaje: 'Este torneo no es tuyo' });
    req.torneo = torneo;
    next();
  } catch (error) {
    fallo(res, error, 'Error al verificar el torneo');
  }
};

export const crearTorneo = async (req, res) => {
  try {
    const { deporte_id, formato_id, ciudad } = req.body;
    const nombre = texto(req.body.nombre, 120);

    if (!nombre || !deporte_id || !formato_id) {
      return res.status(400).json({ mensaje: 'nombre, deporte_id y formato_id son obligatorios' });
    }
    const max_equipos = req.body.max_equipos === undefined ? 16 : entero(req.body.max_equipos, 2, 256);
    const jornada_total = req.body.jornada_total === undefined ? undefined : entero(req.body.jornada_total, 0, 500);
    if (max_equipos === null || jornada_total === null) {
      return res.status(400).json({ mensaje: 'max_equipos (2-256) y jornada_total deben ser números válidos' });
    }

    const torneo = await torneoModel.crear({
      nombre, deporte_id, formato_id, max_equipos, ciudad: texto(ciudad) || null, jornada_total,
      organizador_id: req.usuario.id, // viene del token
    });
    res.status(201).json({ mensaje: 'Torneo creado', torneo });
  } catch (error) {
    fallo(res, error, 'Error al crear el torneo');
  }
};

export const obtenerTorneos = async (req, res) => {
  try {
    res.json(await torneoModel.listarTodos());
  } catch (error) {
    fallo(res, error, 'Error al obtener torneos');
  }
};

export const obtenerTorneoPorId = async (req, res) => {
  try {
    const torneo = await torneoModel.buscarPorId(req.params.id);
    if (!torneo) return res.status(404).json({ mensaje: 'Torneo no encontrado' });
    res.json(torneo);
  } catch (error) {
    fallo(res, error, 'Error al obtener el torneo');
  }
};

export const obtenerTorneosPorOrganizador = async (req, res) => {
  try {
    res.json(await torneoModel.listarPorOrganizador(req.params.organizadorId));
  } catch (error) {
    fallo(res, error, 'Error al obtener los torneos');
  }
};

export const actualizarTorneo = async (req, res) => {
  try {
    // Lista blanca: el organizador y los campos internos no se cambian por aquí
    const cambios = pick(req.body, ['nombre', 'deporte_id', 'formato_id', 'max_equipos', 'ciudad', 'jornada_total', 'jornada_actual', 'estado']);
    if (!Object.keys(cambios).length) return res.status(400).json({ mensaje: 'No hay campos válidos para actualizar' });
    res.json({ mensaje: 'Torneo actualizado', torneo: await torneoModel.actualizar(req.params.id, cambios) });
  } catch (error) {
    fallo(res, error, 'Error al actualizar el torneo');
  }
};

export const eliminarTorneo = async (req, res) => {
  try {
    await torneoModel.eliminar(req.params.id);
    res.json({ mensaje: 'Torneo eliminado' });
  } catch (error) {
    fallo(res, error, 'Error al eliminar el torneo');
  }
};

// GRUPOS

export const crearGrupo = async (req, res) => {
  try {
    const nombre = texto(req.body.nombre, 60);
    if (!nombre) return res.status(400).json({ mensaje: 'El nombre del grupo es obligatorio' });
    res.status(201).json({ mensaje: 'Grupo creado', grupo: await torneoModel.crearGrupo({ torneo_id: req.params.id, nombre }) });
  } catch (error) {
    fallo(res, error, 'Error al crear el grupo');
  }
};

export const obtenerGruposPorTorneo = async (req, res) => {
  try {
    res.json(await torneoModel.listarGruposPorTorneo(req.params.id));
  } catch (error) {
    fallo(res, error, 'Error al obtener los grupos');
  }
};

// RESUMEN: todo lo que muestra la pestaña "Resumen" de un torneo (público, como la tabla de posiciones)
export const resumenTorneo = async (req, res) => {
  try {
    const torneo = await torneoModel.buscarPorId(req.params.id);
    if (!torneo) return res.status(404).json({ mensaje: 'Torneo no encontrado' });

    const [inscripciones, eventos, tabla] = await Promise.all([
      supabase.from('inscripciones_equipo').select('id, estado').eq('torneo_id', torneo.id).then(datos),
      panelModel.eventosPor('torneo_id', [torneo.id], { limite: 1000 }),
      inscripcionModel.obtenerTablaPorTorneo(torneo.id),
    ]);

    const partidos = eventos.filter((e) => e.tipo === 'Partido');
    const contar = (estado) => partidos.filter((p) => p.estado === estado).length;
    const jugados = partidos.filter((p) => p.estado === 'Finalizado' && p.resultado_local != null && p.resultado_visitante != null);
    const goles = jugados.reduce((a, p) => a + p.resultado_local + p.resultado_visitante, 0);

    // Líder: mismo criterio de desempate que la tabla de posiciones
    const ordenada = [...tabla].sort((a, b) => b.puntos - a.puntos || (b.goles_favor - b.goles_contra) - (a.goles_favor - a.goles_contra) || b.goles_favor - a.goles_favor);
    const lider = ordenada[0]?.inscripciones_equipo?.equipos
      ? { equipo: ordenada[0].inscripciones_equipo.equipos, puntos: ordenada[0].puntos, pj: ordenada[0].victorias + ordenada[0].empates + ordenada[0].derrotas }
      : null;

    // Goleadores: suma de goles por jugador en los partidos del torneo
    const idsEventos = eventos.map((e) => e.id);
    const filas = idsEventos.length
      ? datos(await supabase.from('estadisticas_jugador').select('usuario_id, goles, usuarios ( nombre, apellido ), equipos ( nombre )').in('evento_id', idsEventos).gt('goles', 0))
      : [];
    const porJugador = new Map();
    for (const f of filas) {
      const previo = porJugador.get(String(f.usuario_id)) ?? { usuario_id: f.usuario_id, nombre: f.usuarios?.nombre ?? '', apellido: f.usuarios?.apellido ?? '', equipo: f.equipos?.nombre ?? '', goles: 0 };
      previo.goles += f.goles;
      porJugador.set(String(f.usuario_id), previo);
    }
    const goleadores = [...porJugador.values()].sort((a, b) => b.goles - a.goles).slice(0, 5);

    const hoy = ahora().fecha;
    const dia = (e) => String(e.fecha).slice(0, 10);
    const proximo = partidos.find((p) => !['Finalizado', 'Cancelado'].includes(p.estado) && dia(p) >= hoy) ?? null;
    const ultimo = [...jugados].reverse()[0] ?? null;
    const [proximoConTorneo, ultimoConTorneo] = await Promise.all([
      proximo ? panelModel.conTorneo([proximo]).then((l) => l[0]) : null,
      ultimo ? panelModel.conTorneo([ultimo]).then((l) => l[0]) : null,
    ]);

    res.json({
      torneo,
      equipos: {
        aceptados: inscripciones.filter((i) => i.estado === 'Aceptado').length,
        pendientes: inscripciones.filter((i) => i.estado === 'Pendiente').length,
        rechazados: inscripciones.filter((i) => i.estado === 'Rechazado').length,
        max: torneo.max_equipos,
      },
      partidos: { total: partidos.length, programados: contar('Programado'), enVivo: contar('En vivo'), finalizados: contar('Finalizado'), aplazados: contar('Aplazado'), cancelados: contar('Cancelado') },
      goles: { total: goles, promedio: jugados.length ? Math.round((goles / jugados.length) * 100) / 100 : 0 },
      lider,
      proximo: proximoConTorneo,
      ultimo: ultimoConTorneo,
      goleadores,
    });
  } catch (error) {
    fallo(res, error, 'Error al obtener el resumen del torneo');
  }
};
