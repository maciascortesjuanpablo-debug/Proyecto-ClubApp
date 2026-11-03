import { supabase } from '../config/supabase.js';
import { equipoModel } from '../models/equipos.js';
import { panelModel } from '../models/panel.js';
import { ROLES, datos, fallo, pick, texto } from '../utils/helpers.js';
import { esDuenoEquipo } from '../utils/permisos.js';
import { eliminarImagen } from '../utils/cloudinaryutils.js';

// Middleware: carga el equipo de :id y exige que el usuario sea su dueño (o Admin)
export const equipoPropio = async (req, res, next) => {
  try {
    const equipo = await equipoModel.buscarPorId(req.params.id);
    if (!equipo) return res.status(404).json({ mensaje: 'Equipo no encontrado' });
    if (!esDuenoEquipo(req, equipo)) return res.status(403).json({ mensaje: 'Este equipo no es tuyo' });
    req.equipo = equipo;
    next();
  } catch (error) {
    fallo(res, error, 'Error al verificar el equipo');
  }
};


// ---- FICHA DEL EQUIPO ----
const FORMATOS = ['Fútbol 11', 'Fútbol 7', 'Fútbol 5', 'Fútbol sala'];

// Valida y limpia los campos opcionales de la ficha. Devuelve { campos } o { error }.
const camposEquipo = (body) => {
  const campos = {};
  for (const [clave, largo] of [['eslogan', 120], ['descripcion', 500], ['ciudad', 80]]) {
    if (body[clave] !== undefined) campos[clave] = texto(body[clave], largo) || null;
  }
  if (body.formato !== undefined && body.formato !== null && body.formato !== '') {
    if (!FORMATOS.includes(body.formato)) return { error: 'Formato de juego no válido' };
    campos.formato = body.formato;
  }
  if (body.formacion !== undefined && body.formacion !== null && body.formacion !== '') {
    if (!/^[1-9](-[1-9]){1,4}$/.test(String(body.formacion))) return { error: 'Formación no válida (ej. 4-4-2)' };
    campos.formacion = String(body.formacion);
  }
  if (body.max_jugadores !== undefined && body.max_jugadores !== null && body.max_jugadores !== '') {
    const n = Number(body.max_jugadores);
    if (!Number.isInteger(n) || n < 1 || n > 60) return { error: 'La cantidad de jugadores debe estar entre 1 y 60' };
    campos.max_jugadores = n;
  }
  if (body.color_principal !== undefined && body.color_principal !== null && body.color_principal !== '') {
    if (!/^#[0-9a-fA-F]{6}$/.test(String(body.color_principal))) return { error: 'Color no válido (ej. #1E88E5)' };
    campos.color_principal = String(body.color_principal);
  }
  return { campos };
};

// ¿La plantilla ya alcanzó el cupo definido por el entrenador? (sin cupo = sin límite)
export const plantillaLlena = async (equipo) => {
  if (!equipo?.max_jugadores) return false;
  const actual = (await panelModel.contarJugadores([equipo.id]))[equipo.id] ?? 0;
  return actual >= equipo.max_jugadores;
};

export const crearEquipo = async (req, res) => {
  try {
    const nombre = texto(req.body.nombre, 80);
    if (!nombre) return res.status(400).json({ mensaje: 'El nombre del equipo es obligatorio' });

    const ficha = camposEquipo(req.body);
    if (ficha.error) return res.status(400).json({ mensaje: ficha.error });
    const basico = { nombre, logo_url: req.body.logo_url };
    let equipo;
    let aviso;
    try {
      equipo = await equipoModel.crear({ ...basico, ...ficha.campos, creado_por: req.usuario.id });
    } catch (error) {
      // Faltan columnas: ejecuta backend/sql/001_propietarios.sql y backend/sql/002_equipos_ampliado.sql
      if (!/creado_por|eslogan|descripcion|ciudad|formato|formacion|max_jugadores|color_principal|schema cache/.test(error.message)) throw error;
      console.warn('⚠️  Faltan columnas de equipos (ver backend/sql/001 y 002)');
      aviso = 'El equipo se creó solo con su nombre: falta ejecutar backend/sql/002_equipos_ampliado.sql en Supabase';
      try {
        equipo = await equipoModel.crear({ ...basico, creado_por: req.usuario.id });
      } catch (e2) {
        if (!/creado_por/.test(e2.message)) throw e2;
        equipo = await equipoModel.crear(basico);
      }
    }
    res.status(201).json({ mensaje: 'Equipo creado', equipo, aviso });
  } catch (error) {
    fallo(res, error, 'Error al crear el equipo');
  }
};

export const obtenerEquipos = async (req, res) => {
  try {
    res.json(await equipoModel.listarTodos());
  } catch (error) {
    fallo(res, error, 'Error al obtener equipos');
  }
};

export const obtenerEquipoPorId = async (req, res) => {
  try {
    const equipo = await equipoModel.buscarPorId(req.params.id);
    if (!equipo) return res.status(404).json({ mensaje: 'Equipo no encontrado' });
    res.json(equipo);
  } catch (error) {
    fallo(res, error, 'Error al obtener el equipo');
  }
};

export const actualizarEquipo = async (req, res) => {
  try {
    const ficha = camposEquipo(req.body);
    if (ficha.error) return res.status(400).json({ mensaje: ficha.error });
    const cambios = { ...pick(req.body, ['nombre', 'logo_url']), ...ficha.campos };
    if (!Object.keys(cambios).length) return res.status(400).json({ mensaje: 'No hay campos válidos para actualizar' });
    res.json({ mensaje: 'Equipo actualizado', equipo: await equipoModel.actualizar(req.params.id, cambios) });
  } catch (error) {
    fallo(res, error, 'Error al actualizar el equipo');
  }
};

export const eliminarEquipo = async (req, res) => {
  try {
    await equipoModel.eliminar(req.params.id);
    res.json({ mensaje: 'Equipo eliminado' });
  } catch (error) {
    fallo(res, error, 'Error al eliminar el equipo');
  }
};

// ---- JUGADORES ----

export const agregarJugadorEquipo = async (req, res) => {
  try {
    const { usuario_id, posicion, dorsal } = req.body;
    if (!usuario_id || !posicion) return res.status(400).json({ mensaje: 'usuario_id y posicion son obligatorios' });
    if (await equipoModel.buscarJugador(req.params.id, usuario_id)) {
      return res.status(409).json({ mensaje: 'El jugador ya está en el equipo' });
    }
    if (await plantillaLlena(req.equipo ?? (await equipoModel.buscarPorId(req.params.id)))) return res.status(409).json({ mensaje: 'La plantilla ya alcanzó su cupo de jugadores' });
    const jugador = await equipoModel.agregarJugador({ equipo_id: req.params.id, usuario_id, posicion, dorsal });
    res.status(201).json({ mensaje: 'Jugador agregado al equipo', jugador });
  } catch (error) {
    fallo(res, error, 'Error al agregar el jugador');
  }
};

export const obtenerPlantilla = async (req, res) => {
  try {
    res.json(await equipoModel.listarJugadores(req.params.id));
  } catch (error) {
    fallo(res, error, 'Error al obtener la plantilla');
  }
};

export const actualizarJugadorEquipo = async (req, res) => {
  try {
    const cambios = pick(req.body, ['posicion', 'dorsal', 'estado_convocatoria', 'es_titular', 'slot_campo']);
    if (!Object.keys(cambios).length) return res.status(400).json({ mensaje: 'No hay campos válidos para actualizar' });
    res.json({ mensaje: 'Jugador actualizado', jugador: await equipoModel.actualizarJugador(req.params.id, req.params.usuarioId, cambios) });
  } catch (error) {
    fallo(res, error, 'Error al actualizar el jugador');
  }
};

export const eliminarJugadorEquipo = async (req, res) => {
  try {
    await equipoModel.eliminarJugador(req.params.id, req.params.usuarioId);
    res.json({ mensaje: 'Jugador eliminado del equipo' });
  } catch (error) {
    fallo(res, error, 'Error al eliminar el jugador');
  }
};

// ---- STAFF ----

export const agregarStaffEquipo = async (req, res) => {
  try {
    const { usuario_id, cargo } = req.body;
    if (!usuario_id || !cargo) return res.status(400).json({ mensaje: 'usuario_id y cargo son obligatorios' });
    const staff = await equipoModel.agregarStaff({ equipo_id: req.params.id, usuario_id, cargo });
    res.status(201).json({ mensaje: 'Staff agregado', staff });
  } catch (error) {
    fallo(res, error, 'Error al agregar el staff');
  }
};

export const obtenerStaffEquipo = async (req, res) => {
  try {
    res.json(await equipoModel.listarStaff(req.params.id));
  } catch (error) {
    fallo(res, error, 'Error al obtener el staff');
  }
};

export const eliminarStaffEquipo = async (req, res) => {
  try {
    await equipoModel.eliminarStaff(req.params.id, req.params.usuarioId);
    res.json({ mensaje: 'Staff eliminado del equipo' });
  } catch (error) {
    fallo(res, error, 'Error al eliminar el staff');
  }
};

// ---- EQUIPOS PROPIOS Y PARTIDOS ----

// Mis equipos según mi rol: el entrenador ve los que dirige; el jugador, aquellos donde juega.
export const misEquipos = async (req, res) => {
  try {
    const { id, rol_id } = req.usuario;
    const lista = rol_id === ROLES.ENTRENADOR ? await panelModel.equiposDeEntrenador(id) : await panelModel.equiposDeJugador(id);
    const conteo = await panelModel.contarJugadores(lista.map((e) => e.id));
    res.json(lista.map((e) => ({ ...e, jugadores: conteo[e.id] ?? 0 })));
  } catch (error) {
    fallo(res, error, 'Error al obtener tus equipos');
  }
};

// Partidos de un equipo (de local o de visitante) con su balance. Es información pública, como la tabla de posiciones.
export const partidosDeEquipo = async (req, res) => {
  try {
    const equipo = await equipoModel.buscarPorId(req.params.id);
    if (!equipo) return res.status(404).json({ mensaje: 'Equipo no encontrado' });

    const [local, visitante] = await Promise.all([
      panelModel.eventosPor('equipo_local_id', [equipo.id], { limite: 200 }),
      panelModel.eventosPor('equipo_visitante_id', [equipo.id], { limite: 200 }),
    ]);
    const partidos = await panelModel.conTorneo(panelModel.unir(local, visitante));

    const balance = { pj: 0, g: 0, e: 0, p: 0, gf: 0, gc: 0 };
    for (const p of partidos) {
      if (p.tipo !== 'Partido' || p.estado !== 'Finalizado' || p.resultado_local == null || p.resultado_visitante == null) continue;
      const esLocal = String(p.equipo_local_id) === String(equipo.id);
      const [gf, gc] = esLocal ? [p.resultado_local, p.resultado_visitante] : [p.resultado_visitante, p.resultado_local];
      balance.pj++; balance.gf += gf; balance.gc += gc;
      if (gf > gc) balance.g++; else if (gf === gc) balance.e++; else balance.p++;
    }
    res.json({ equipo, partidos, balance });
  } catch (error) {
    fallo(res, error, 'Error al obtener los partidos del equipo');
  }
};

// Buscador de jugadores para invitarlos (solo entrenadores y admin). Devuelve lo mínimo: nombre, ciudad, nivel y posición.
export const buscarJugadores = async (req, res) => {
  try {
    const q = texto(req.query.q, 60).replace(/[%,()*\\]/g, ' ').trim();
    let consulta = supabase.from('usuarios').select('id, nombre, apellido, ciudad, nivel_juego').eq('rol_id', ROLES.JUGADOR).eq('activo', true).order('nombre').limit(20);
    if (q) consulta = consulta.or(`nombre.ilike.%${q}%,apellido.ilike.%${q}%`);
    const jugadores = datos(await consulta);

    const ids = jugadores.map((j) => j.id);
    const perfiles = ids.length ? datos(await supabase.from('perfil_jugador').select('usuario_id, posicion').in('usuario_id', ids)) : [];
    const posicion = Object.fromEntries(perfiles.map((p) => [String(p.usuario_id), p.posicion]));

    // Si se indica el equipo, se excluyen quienes ya están en su plantilla
    let enEquipo = new Set();
    if (req.query.equipoId) {
      const filas = datos(await supabase.from('equipo_jugadores').select('usuario_id').eq('equipo_id', req.query.equipoId));
      enEquipo = new Set(filas.map((f) => String(f.usuario_id)));
    }
    res.json(jugadores.filter((j) => !enEquipo.has(String(j.id))).map((j) => ({ ...j, posicion: posicion[String(j.id)] ?? null })));
  } catch (error) {
    fallo(res, error, 'Error al buscar jugadores');
  }
};

// Escudo del equipo (imagen subida a Cloudinary por el middleware)
export const actualizarLogoEquipo = async (req, res) => {
  try {
    if (!req.file) return res.status(400).json({ mensaje: 'No se envió ninguna imagen' });
    if (req.equipo.logo_url) await eliminarImagen(req.equipo.logo_url);
    res.json({ mensaje: 'Escudo actualizado', equipo: await equipoModel.actualizar(req.params.id, { logo_url: req.file.path }) });
  } catch (error) {
    fallo(res, error, 'Error al actualizar el escudo');
  }
};

// Guarda la alineación del campo: formación + qué jugador ocupa cada casilla.
// Todos los demás jugadores pasan a suplentes. Cuerpo: { formacion, titulares: [{ usuario_id, slot, posicion }] }
export const guardarAlineacion = async (req, res) => {
  try {
    const { formacion, titulares } = req.body;
    if (!Array.isArray(titulares)) return res.status(400).json({ mensaje: 'titulares debe ser una lista' });
    if (formacion !== undefined && !/^[1-9](-[1-9]){1,4}$/.test(String(formacion))) return res.status(400).json({ mensaje: 'Formación no válida' });

    const slots = titulares.map((t) => Number(t.slot));
    if (slots.some((s) => !Number.isInteger(s) || s < 0 || s > 20) || new Set(slots).size !== slots.length) return res.status(400).json({ mensaje: 'Casillas repetidas o no válidas' });
    const usuarios = titulares.map((t) => String(t.usuario_id));
    if (new Set(usuarios).size !== usuarios.length) return res.status(400).json({ mensaje: 'Un jugador no puede ocupar dos casillas' });

    const plantilla = await equipoModel.listarJugadores(req.params.id);
    const enEquipo = new Set(plantilla.map((j) => String(j.usuarios?.id)));
    if (usuarios.some((u) => !enEquipo.has(u))) return res.status(400).json({ mensaje: 'Hay jugadores que no pertenecen al equipo' });

    // 1) Todos a suplentes  2) cada titular a su casilla
    datos(await supabase.from('equipo_jugadores').update({ es_titular: false, slot_campo: null }).eq('equipo_id', req.params.id));
    for (const t of titulares) {
      const cambios = { es_titular: true, slot_campo: Number(t.slot) };
      if (t.posicion) cambios.posicion = texto(t.posicion, 40);
      await equipoModel.actualizarJugador(req.params.id, t.usuario_id, cambios);
    }
    if (formacion) await equipoModel.actualizar(req.params.id, { formacion: String(formacion) });
    res.json({ mensaje: 'Alineación guardada', titulares: titulares.length });
  } catch (error) {
    fallo(res, error, 'Error al guardar la alineación');
  }
};