import { supabase } from '../config/supabase.js';
import { equipoModel } from '../models/equipos.js';
import { panelModel } from '../models/panel.js';
import { ROLES, datos, fallo, pick, texto } from '../utils/helpers.js';
import { esDuenoEquipo } from '../utils/permisos.js';

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

export const crearEquipo = async (req, res) => {
  try {
    const nombre = texto(req.body.nombre, 80);
    if (!nombre) return res.status(400).json({ mensaje: 'El nombre del equipo es obligatorio' });

    const nuevo = { nombre, logo_url: req.body.logo_url };
    let equipo;
    try {
      equipo = await equipoModel.crear({ ...nuevo, creado_por: req.usuario.id });
    } catch (error) {
      // Columna `creado_por` aún no creada: ejecuta backend/sql/001_propietarios.sql
      if (!/creado_por/.test(error.message)) throw error;
      console.warn('⚠️  Falta la columna equipos.creado_por (ver backend/sql/001_propietarios.sql)');
      equipo = await equipoModel.crear(nuevo);
    }
    res.status(201).json({ mensaje: 'Equipo creado', equipo });
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
    const cambios = pick(req.body, ['nombre', 'logo_url']);
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
    const cambios = pick(req.body, ['posicion', 'dorsal', 'estado_convocatoria', 'es_titular']);
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
