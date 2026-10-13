import { equipoModel } from '../models/equipos.js';
import { fallo, pick, texto } from '../utils/helpers.js';
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
