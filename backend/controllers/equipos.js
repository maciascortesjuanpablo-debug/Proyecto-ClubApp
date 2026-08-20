import { equipoModel } from '../models/equipos.js';

export const crearEquipo = async (req, res) => {
  try {
    const { nombre, logo_url } = req.body;

    if (!nombre) {
      return res.status(400).json({ mensaje: 'El nombre del equipo es obligatorio' });
    }

    const equipo = await equipoModel.crear({ nombre, logo_url });
    res.status(201).json({ mensaje: 'Equipo creado', equipo });

  } catch (error) {
    console.error(error);
    res.status(500).json({ mensaje: 'Error al crear el equipo', error: error.message });
  }
};

export const obtenerEquipos = async (req, res) => {
  try {
    const equipos = await equipoModel.listarTodos();
    res.json(equipos);
  } catch (error) {
    console.error(error);
    res.status(500).json({ mensaje: 'Error al obtener equipos', error: error.message });
  }
};

export const obtenerEquipoPorId = async (req, res) => {
  try {
    const { id } = req.params;
    const equipo = await equipoModel.buscarPorId(id);

    if (!equipo) {
      return res.status(404).json({ mensaje: 'Equipo no encontrado' });
    }

    res.json(equipo);
  } catch (error) {
    console.error(error);
    res.status(500).json({ mensaje: 'Error al obtener el equipo', error: error.message });
  }
};

export const actualizarEquipo = async (req, res) => {
  try {
    const { id } = req.params;
    const equipo = await equipoModel.actualizar(id, req.body);
    res.json({ mensaje: 'Equipo actualizado', equipo });
  } catch (error) {
    console.error(error);
    res.status(500).json({ mensaje: 'Error al actualizar el equipo', error: error.message });
  }
};

export const eliminarEquipo = async (req, res) => {
  try {
    const { id } = req.params;
    await equipoModel.eliminar(id);
    res.json({ mensaje: 'Equipo eliminado' });
  } catch (error) {
    console.error(error);
    res.status(500).json({ mensaje: 'Error al eliminar el equipo', error: error.message });
  }
};

// ---- JUGADORES ----

export const agregarJugadorEquipo = async (req, res) => {
  try {
    const { id } = req.params; // equipo_id
    const { usuario_id, posicion, dorsal } = req.body;

    if (!usuario_id || !posicion) {
      return res.status(400).json({ mensaje: 'usuario_id y posicion son obligatorios' });
    }

    const jugador = await equipoModel.agregarJugador({ equipo_id: id, usuario_id, posicion, dorsal });
    res.status(201).json({ mensaje: 'Jugador agregado al equipo', jugador });

  } catch (error) {
    console.error(error);
    res.status(500).json({ mensaje: 'Error al agregar el jugador', error: error.message });
  }
};

export const obtenerPlantilla = async (req, res) => {
  try {
    const { id } = req.params;
    const jugadores = await equipoModel.listarJugadores(id);
    res.json(jugadores);
  } catch (error) {
    console.error(error);
    res.status(500).json({ mensaje: 'Error al obtener la plantilla', error: error.message });
  }
};

export const actualizarJugadorEquipo = async (req, res) => {
  try {
    const { id, usuarioId } = req.params;
    const jugador = await equipoModel.actualizarJugador(id, usuarioId, req.body);
    res.json({ mensaje: 'Jugador actualizado', jugador });
  } catch (error) {
    console.error(error);
    res.status(500).json({ mensaje: 'Error al actualizar el jugador', error: error.message });
  }
};

export const eliminarJugadorEquipo = async (req, res) => {
  try {
    const { id, usuarioId } = req.params;
    await equipoModel.eliminarJugador(id, usuarioId);
    res.json({ mensaje: 'Jugador eliminado del equipo' });
  } catch (error) {
    console.error(error);
    res.status(500).json({ mensaje: 'Error al eliminar el jugador', error: error.message });
  }
};

// ---- STAFF ----

export const agregarStaffEquipo = async (req, res) => {
  try {
    const { id } = req.params;
    const { usuario_id, cargo } = req.body;

    if (!usuario_id || !cargo) {
      return res.status(400).json({ mensaje: 'usuario_id y cargo son obligatorios' });
    }

    const staff = await equipoModel.agregarStaff({ equipo_id: id, usuario_id, cargo });
    res.status(201).json({ mensaje: 'Staff agregado', staff });

  } catch (error) {
    console.error(error);
    res.status(500).json({ mensaje: 'Error al agregar el staff', error: error.message });
  }
};

export const obtenerStaffEquipo = async (req, res) => {
  try {
    const { id } = req.params;
    const staff = await equipoModel.listarStaff(id);
    res.json(staff);
  } catch (error) {
    console.error(error);
    res.status(500).json({ mensaje: 'Error al obtener el staff', error: error.message });
  }
};

export const eliminarStaffEquipo = async (req, res) => {
  try {
    const { id, usuarioId } = req.params;
    await equipoModel.eliminarStaff(id, usuarioId);
    res.json({ mensaje: 'Staff eliminado del equipo' });
  } catch (error) {
    console.error(error);
    res.status(500).json({ mensaje: 'Error al eliminar el staff', error: error.message });
  }
};