import { supabase } from '../config/supabase.js';
import { calendarioModel } from '../models/calendario.js';
import { inscripcionModel } from '../models/inscripciones.js';
import { FECHA_RE, HORA_RE, ahora, datos, entero, fallo } from '../utils/helpers.js';
import { generarRondas, mezclar, programar, sumarDias } from '../utils/fixture.js';
import { avisarFixtureCreado } from '../utils/avisos.js';

// Fixture automático: el organizador elige equipos, formato, fechas y horarios, y los partidos se crean y se reparten solos.
// Dos pasos: previsualizar (no guarda nada) y crear (guarda en el calendario).

const MODOS = ['todos', 'ida_vuelta', 'grupos', 'eliminacion'];
const MAX_PARTIDOS = 400;
const HORIZONTE_DIAS = 400;
const REEMPLAZABLES = ['Programado', 'Aplazado']; // se pueden volver a generar
const BLOQUEANTES = ['En vivo', 'Finalizado']; // ya hay juego real: no se regenera

const hhmm = (h) => String(h).slice(0, 5);

// Valida la configuración y arma la propuesta completa. Devuelve { error, estado? } o la propuesta
const construir = async (torneo, cfg) => {
  if (['Finalizado', 'Cancelado'].includes(torneo.estado)) return { error: 'El torneo ya terminó: no se pueden programar más partidos', estado: 409 };

  const modo = cfg.modo;
  if (!MODOS.includes(modo)) return { error: `El formato debe ser: ${MODOS.join(', ')}` };

  // Equipos: solo los aceptados en el torneo, en el orden elegido (el orden es la siembra en eliminación y grupos)
  const aceptados = (await inscripcionModel.equiposAceptados(torneo.id)).map(String);
  const pedidos = Array.isArray(cfg.equipos) && cfg.equipos.length ? cfg.equipos.map(String) : aceptados;
  let equipos = [...new Set(pedidos)];
  if (equipos.some((e) => !aceptados.includes(e))) return { error: 'Solo puedes elegir equipos aceptados en el torneo' };
  if (equipos.length < 2) return { error: 'Elige al menos 2 equipos' };
  if (equipos.length > 64) return { error: 'El máximo es de 64 equipos' };

  let numGrupos = 2;
  if (modo === 'grupos') {
    numGrupos = entero(cfg.num_grupos, 2, 8);
    if (numGrupos === null) return { error: 'La cantidad de grupos debe estar entre 2 y 8' };
    if (equipos.length < numGrupos * 2) return { error: `Con ${numGrupos} grupos necesitas al menos ${numGrupos * 2} equipos` };
  }

  const hoy = ahora();
  if (!FECHA_RE.test(cfg.fecha_inicio ?? '')) return { error: 'La fecha de inicio debe ser AAAA-MM-DD' };
  if (cfg.fecha_inicio < hoy.fecha) return { error: 'La fecha de inicio no puede ser pasada' };

  const dias = Array.isArray(cfg.dias) ? [...new Set(cfg.dias.map(Number))] : [];
  if (!dias.length || dias.some((d) => !Number.isInteger(d) || d < 0 || d > 6)) return { error: 'Elige al menos un día de la semana' };

  const horas = Array.isArray(cfg.horas) ? [...new Set(cfg.horas.map(String))] : [];
  if (!horas.length || horas.length > 8 || horas.some((h) => !HORA_RE.test(h))) return { error: 'Elige entre 1 y 8 horarios válidos (HH:MM)' };
  const horasOrdenadas = horas.map(hhmm).sort();

  const sedesPedidas = Array.isArray(cfg.sedes) ? [...new Set(cfg.sedes.map(String))] : [];
  const sedesBD = await calendarioModel.listarSedes();
  if (sedesPedidas.some((s) => !sedesBD.some((x) => String(x.id) === s))) return { error: 'Alguna de las sedes elegidas no existe' };
  const simultaneos = cfg.simultaneos === undefined ? 1 : entero(cfg.simultaneos, 1, 8);
  if (simultaneos === null) return { error: 'Los partidos simultáneos deben estar entre 1 y 8' };

  // Partidos que ya tiene el torneo
  const existentes = datos(await supabase.from('eventos_calendario').select('id, estado').eq('torneo_id', torneo.id).eq('tipo', 'Partido'));
  const reemplazables = existentes.filter((e) => REEMPLAZABLES.includes(e.estado));
  const bloqueantes = existentes.filter((e) => BLOQUEANTES.includes(e.estado));
  const aReemplazar = new Set(cfg.reemplazar ? reemplazables.map((e) => String(e.id)) : []);

  // Lo ya ocupado en el calendario (de cualquier torneo): sedes y equipos por fecha y hora
  const hasta = sumarDias(cfg.fecha_inicio, HORIZONTE_DIAS);
  const agenda = datos(await supabase.from('eventos_calendario').select('id, fecha, hora, lugar_id, equipo_local_id, equipo_visitante_id, estado')
    .gte('fecha', cfg.fecha_inicio).lte('fecha', hasta).neq('estado', 'Cancelado').limit(5000));
  const ocupados = { sedes: new Set(), equipos: new Set() };
  for (const e of agenda) {
    if (aReemplazar.has(String(e.id))) continue;
    const dia = String(e.fecha).split('T')[0];
    if (e.lugar_id) ocupados.sedes.add(`${dia}|${hhmm(e.hora)}|${e.lugar_id}`);
    for (const eq of [e.equipo_local_id, e.equipo_visitante_id]) if (eq) ocupados.equipos.add(`${dia}|${hhmm(e.hora)}|${eq}`);
  }

  // Sorteo (opcional) con semilla: la misma semilla da el mismo resultado en la vista previa y al crear
  if (cfg.sorteo) equipos = mezclar(equipos, entero(cfg.semilla, 1, 2_000_000_000) ?? 1);

  const generado = generarRondas({ modo, equipos, numGrupos, idaVueltaGrupos: !!cfg.ida_vuelta_grupos });
  const total = generado.rondas.reduce((a, r) => a + r.partidos.length, 0);
  if (total === 0) return { error: 'Con esos equipos no se genera ningún partido' };
  if (total > MAX_PARTIDOS) return { error: `Se generarían ${total} partidos y el máximo es ${MAX_PARTIDOS}. Elige menos equipos o un formato más corto.` };

  let partidos;
  try {
    partidos = programar(generado.rondas, { fechaInicio: cfg.fecha_inicio, dias, horas: horasOrdenadas, sedes: sedesPedidas, simultaneos, ocupados, hoy, horizonte: HORIZONTE_DIAS });
  } catch (e) {
    return { error: e.message };
  }
  partidos.sort((a, b) => `${a.fecha} ${a.hora}`.localeCompare(`${b.fecha} ${b.hora}`) || a.jornada - b.jornada);

  // Nombres para mostrar
  const ids = [...new Set(equipos)];
  const nombresEq = Object.fromEntries(datos(await supabase.from('equipos').select('id, nombre').in('id', ids)).map((e) => [String(e.id), e.nombre]));
  const nombresSede = Object.fromEntries(sedesBD.map((s) => [String(s.id), s.nombre]));

  return {
    partidos, nombresEq, nombresSede, equipos, generado,
    existentes: { reemplazables: reemplazables.length, bloqueantes: bloqueantes.length, idsReemplazables: [...aReemplazar] },
    jornadas: new Set(partidos.map((p) => p.jornada)).size,
  };
};

const resumir = (p) => ({
  total: p.partidos.length,
  jornadas: p.jornadas,
  primera: p.partidos[0].fecha,
  ultima: p.partidos[p.partidos.length - 1].fecha,
  equipos: p.equipos.length,
  grupos: p.generado.grupos?.map((g) => ({ nombre: g.nombre, equipos: g.equipos.map((e) => p.nombresEq[e] ?? 'Equipo') })) ?? null,
  descansan: p.generado.directos?.map((e) => p.nombresEq[e] ?? 'Equipo') ?? [],
});

const torneoDe = (req) => req.torneo;

// Vista previa: calcula todo pero no guarda nada
export const previsualizarFixture = async (req, res) => {
  try {
    const p = await construir(torneoDe(req), req.body ?? {});
    if (p.error) return res.status(p.estado ?? 400).json({ mensaje: p.error });

    const advertencias = [];
    if (p.existentes.bloqueantes > 0) advertencias.push(`El torneo ya tiene ${p.existentes.bloqueantes} partido(s) en juego o finalizados: no se puede generar un calendario nuevo.`);
    else if (p.existentes.reemplazables > 0 && !req.body?.reemplazar) advertencias.push(`El torneo ya tiene ${p.existentes.reemplazables} partido(s) programados. Activa "Reemplazar los partidos programados" para generarlos de nuevo.`);

    res.json({
      resumen: resumir(p),
      partidos: p.partidos.map((x) => ({
        jornada: x.jornada, fase: x.fase, fecha: x.fecha, hora: x.hora,
        local: { id: x.local, nombre: p.nombresEq[x.local] ?? 'Equipo' },
        visitante: { id: x.visitante, nombre: p.nombresEq[x.visitante] ?? 'Equipo' },
        sede: x.lugar_id ? p.nombresSede[String(x.lugar_id)] ?? null : null,
      })),
      existentes: p.existentes,
      advertencias,
      puede_crear: p.existentes.bloqueantes === 0 && (p.existentes.reemplazables === 0 || !!req.body?.reemplazar),
    });
  } catch (error) {
    fallo(res, error, 'Error al preparar el calendario');
  }
};

// Crea los partidos en el calendario
export const crearFixture = async (req, res) => {
  try {
    const torneo = torneoDe(req);
    const p = await construir(torneo, req.body ?? {});
    if (p.error) return res.status(p.estado ?? 400).json({ mensaje: p.error });

    if (p.existentes.bloqueantes > 0) return res.status(409).json({ mensaje: 'El torneo ya tiene partidos en juego o finalizados: no se puede generar un calendario nuevo' });
    if (p.existentes.reemplazables > 0 && !req.body?.reemplazar) {
      return res.status(409).json({ mensaje: `El torneo ya tiene ${p.existentes.reemplazables} partido(s) programados. Activa "Reemplazar los partidos programados" para generarlos de nuevo.` });
    }
    if (p.existentes.idsReemplazables.length) {
      datos(await supabase.from('partido_arbitros').delete().in('evento_id', p.existentes.idsReemplazables));
      datos(await supabase.from('eventos_calendario').delete().in('id', p.existentes.idsReemplazables));
    }

    const filas = p.partidos.map((x) => ({
      torneo_id: torneo.id, tipo: 'Partido', estado: 'Programado',
      equipo_local_id: x.local, equipo_visitante_id: x.visitante, fecha: x.fecha, hora: x.hora,
      ...(x.lugar_id ? { lugar_id: x.lugar_id } : {}), jornada: x.jornada, fase: x.fase ?? null,
    }));
    let aviso;
    try {
      datos(await supabase.from('eventos_calendario').insert(filas).select('id'));
    } catch (e) {
      // Falta backend/sql/005_fixture.sql: se guardan los partidos sin jornada ni fase
      if (!/jornada|fase|schema cache/i.test(e.message)) throw e;
      aviso = 'Los partidos se crearon sin jornada ni fase: falta ejecutar backend/sql/005_fixture.sql en Supabase';
      datos(await supabase.from('eventos_calendario').insert(filas.map(({ jornada, fase, ...resto }) => resto)).select('id')); // eslint-disable-line no-unused-vars
    }

    // Para eliminación solo se genera la primera ronda: el total de jornadas no se conoce todavía
    if (req.body.modo !== 'eliminacion') {
      await supabase.from('torneos').update({ jornada_total: p.jornadas }).eq('id', torneo.id).then(() => {}, () => {});
    }

    avisarFixtureCreado(torneo, p.partidos, p.nombresEq, req.usuario.id); // sin await: no hace esperar la respuesta
    res.status(201).json({ mensaje: `Se crearon ${p.partidos.length} partidos`, resumen: resumir(p), aviso });
  } catch (error) {
    fallo(res, error, 'Error al crear el calendario');
  }
};