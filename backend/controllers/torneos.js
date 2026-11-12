import { supabase } from '../config/supabase.js';
import { torneoModel } from '../models/torneos.js';
import { inscripcionModel } from '../models/inscripciones.js';
import { panelModel } from '../models/panel.js';
import { ahora, datos, entero, fallo, texto } from '../utils/helpers.js';
import { avisarTorneoEliminado, avisarTorneoEstado } from '../utils/avisos.js';
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

// Edición de los datos del torneo por su organizador (o el admin). Cada campo se valida;
// el estado tiene su propio endpoint (PUT /:id/estado) porque cerrar un torneo tiene consecuencias.
export const actualizarTorneo = async (req, res) => {
  try {
    const torneo = req.torneo;
    const body = req.body ?? {};
    if (body.estado !== undefined) return res.status(400).json({ mensaje: 'Para finalizar, cancelar o reabrir el torneo usa la opción de estado' });

    const cambios = {};
    if (body.nombre !== undefined) {
      const nombre = texto(body.nombre, 120);
      if (!nombre) return res.status(400).json({ mensaje: 'El nombre no puede estar vacío' });
      cambios.nombre = nombre;
    }
    if (body.ciudad !== undefined) cambios.ciudad = texto(body.ciudad) || null;

    if (body.max_equipos !== undefined) {
      const max = entero(body.max_equipos, 2, 256);
      if (max === null) return res.status(400).json({ mensaje: 'El máximo de equipos debe estar entre 2 y 256' });
      const aceptados = await inscripcionModel.contarAceptadas(torneo.id);
      if (max < aceptados) return res.status(409).json({ mensaje: `Ya hay ${aceptados} equipos aceptados: el máximo no puede ser menor` });
      cambios.max_equipos = max;
    }

    if (body.jornada_total !== undefined) {
      if (body.jornada_total === null || body.jornada_total === '') cambios.jornada_total = null;
      else {
        const j = entero(body.jornada_total, 0, 500);
        if (j === null) return res.status(400).json({ mensaje: 'Las jornadas deben ser un número entre 0 y 500' });
        cambios.jornada_total = j;
      }
    }

    // El deporte y el formato definen cómo se juega: no se cambian cuando ya hay partidos
    if (body.deporte_id !== undefined || body.formato_id !== undefined) {
      const partidos = datos(await supabase.from('eventos_calendario').select('id').eq('torneo_id', torneo.id).eq('tipo', 'Partido').limit(1));
      if (partidos.length) return res.status(409).json({ mensaje: 'No se puede cambiar el deporte ni el formato cuando el torneo ya tiene partidos' });
      if (body.deporte_id !== undefined) cambios.deporte_id = body.deporte_id;
      if (body.formato_id !== undefined) cambios.formato_id = body.formato_id;
    }

    if (!Object.keys(cambios).length) return res.status(400).json({ mensaje: 'No hay campos válidos para actualizar' });
    res.json({ mensaje: 'Torneo actualizado', torneo: await torneoModel.actualizar(torneo.id, cambios) });
  } catch (error) {
    fallo(res, error, 'Error al actualizar el torneo');
  }
};

const ESTADOS_TORNEO = ['Activo', 'Finalizado', 'Cancelado'];
const SIN_JUGAR = ['Programado', 'Aplazado'];

// Finalizar, cancelar o reabrir un torneo. Cerrarlo cancela sus partidos sin jugar (solo con confirmación: forzar) y avisa a los participantes.
// Cuerpo: { estado: 'Activo' | 'Finalizado' | 'Cancelado', forzar?: boolean }
export const cambiarEstadoTorneo = async (req, res) => {
  try {
    const torneo = req.torneo;
    const { estado, forzar } = req.body ?? {};
    if (!ESTADOS_TORNEO.includes(estado)) return res.status(400).json({ mensaje: `El estado debe ser: ${ESTADOS_TORNEO.join(', ')}` });
    if (torneo.estado === estado) return res.status(409).json({ mensaje: `El torneo ya está ${estado.toLowerCase()}` });

    let canceladas = 0;
    if (estado !== 'Activo') {
      const partidos = datos(await supabase.from('eventos_calendario').select('id, estado').eq('torneo_id', torneo.id).eq('tipo', 'Partido'));
      const enVivo = partidos.filter((p) => p.estado === 'En vivo');
      const pendientes = partidos.filter((p) => SIN_JUGAR.includes(p.estado));
      if (enVivo.length) return res.status(409).json({ mensaje: `Hay ${enVivo.length} partido(s) en vivo. Termínalos antes de ${estado === 'Finalizado' ? 'finalizar' : 'cancelar'} el torneo` });
      if (pendientes.length && !forzar) {
        return res.status(409).json({ mensaje: `Hay ${pendientes.length} partido(s) sin jugar. Confirma para cancelarlos y cerrar el torneo` });
      }
      if (pendientes.length) {
        datos(await supabase.from('eventos_calendario').update({ estado: 'Cancelado' }).in('id', pendientes.map((p) => p.id)));
        canceladas = pendientes.length;
      }
    }

    const actualizado = await torneoModel.actualizar(torneo.id, { estado });
    avisarTorneoEstado(torneo, estado, req.usuario.id); // sin await: no hace esperar la respuesta
    res.json({ mensaje: `Torneo ${estado === 'Activo' ? 'reabierto' : estado.toLowerCase()}`, torneo: actualizado, canceladas });
  } catch (error) {
    fallo(res, error, 'Error al cambiar el estado del torneo');
  }
};

// Eliminar un torneo y todo lo que depende de él. Si ya tiene partidos jugados o en juego no se borra: se cancela, para conservar el historial.
export const eliminarTorneo = async (req, res) => {
  try {
    const torneo = req.torneo;
    const [inscripciones, eventos] = await Promise.all([
      supabase.from('inscripciones_equipo').select('id').eq('torneo_id', torneo.id).then(datos),
      supabase.from('eventos_calendario').select('id, tipo, estado').eq('torneo_id', torneo.id).then(datos),
    ]);
    if (eventos.some((e) => e.tipo === 'Partido' && ['Finalizado', 'En vivo'].includes(e.estado))) {
      return res.status(409).json({ mensaje: 'El torneo ya tiene partidos jugados o en juego: no se puede eliminar. Puedes cancelarlo o finalizarlo para conservar el historial' });
    }

    await avisarTorneoEliminado(torneo, req.usuario.id); // antes de borrar: necesita las inscripciones para saber a quién avisar

    const borrar = async (tabla, columna, ids, opcional = false) => {
      if (!ids.length) return;
      try {
        datos(await supabase.from(tabla).delete().in(columna, ids));
      } catch (e) {
        if (!opcional) throw e;
        console.warn(`No se pudo limpiar ${tabla}:`, e.message); // tablas que pueden no existir en tu base
      }
    };
    const idsEventos = eventos.map((e) => e.id);
    const idsInscripciones = inscripciones.map((i) => i.id);
    await borrar('estadisticas_jugador', 'evento_id', idsEventos);
    await borrar('partido_arbitros', 'evento_id', idsEventos);
    await borrar('eventos_calendario', 'id', idsEventos);
    await borrar('tabla_posiciones', 'inscripcion_id', idsInscripciones);
    await borrar('inscripciones_equipo', 'id', idsInscripciones);
    await borrar('grupos_torneo', 'torneo_id', [torneo.id], true);
    await borrar('favoritos', 'torneo_id', [torneo.id], true);
    await borrar('scout_ai_recomendaciones', 'torneo_id', [torneo.id], true);
    await torneoModel.eliminar(torneo.id);
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