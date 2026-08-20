import { torneoModel } from '../models/torneos.js';

export const crearTorneo = async (req, res) => {
  try {
    const { nombre, deporte_id, formato_id, max_equipos, ciudad, jornada_total } = req.body;

    if (!nombre || !deporte_id || !formato_id) {
      return res.status(400).json({ mensaje: 'nombre, deporte_id y formato_id son obligatorios' });
    }

    const torneo = await torneoModel.crear({
      nombre,
      deporte_id,
      formato_id,
      max_equipos: max_equipos || 16,
      ciudad,
      jornada_total,
      organizador_id: req.usuario.id // viene del token
    });

    res.status(201).json({ mensaje: 'Torneo creado', torneo });

  } catch (error) {
    console.error(error);
    res.status(500).json({ mensaje: 'Error al crear el torneo', error: error.message });
  }
};

export const obtenerTorneos = async (req, res) => {
  try {
    const torneos = await torneoModel.listarTodos();
    res.json(torneos);
  } catch (error) {
    console.error(error);
    res.status(500).json({ mensaje: 'Error al obtener torneos', error: error.message });
  }
};

export const obtenerTorneoPorId = async (req, res) => {
  try {
    const { id } = req.params;
    const torneo = await torneoModel.buscarPorId(id);

    if (!torneo) {
      return res.status(404).json({ mensaje: 'Torneo no encontrado' });
    }

    res.json(torneo);
  } catch (error) {
    console.error(error);
    res.status(500).json({ mensaje: 'Error al obtener el torneo', error: error.message });
  }
};

export const obtenerTorneosPorOrganizador = async (req, res) => {
  try {
    const { organizadorId } = req.params;
    const torneos = await torneoModel.listarPorOrganizador(organizadorId);
    res.json(torneos);
  } catch (error) {
    console.error(error);
    res.status(500).json({ mensaje: 'Error al obtener los torneos', error: error.message });
  }
};

export const actualizarTorneo = async (req, res) => {
  try {
    const { id } = req.params;
    const { organizador_id, ...datosPermitidos } = req.body; // el organizador no se cambia por aquí

    const torneo = await torneoModel.actualizar(id, datosPermitidos);
    res.json({ mensaje: 'Torneo actualizado', torneo });

  } catch (error) {
    console.error(error);
    res.status(500).json({ mensaje: 'Error al actualizar el torneo', error: error.message });
  }
};

export const eliminarTorneo = async (req, res) => {
  try {
    const { id } = req.params;
    await torneoModel.eliminar(id);
    res.json({ mensaje: 'Torneo eliminado' });
  } catch (error) {
    console.error(error);
    res.status(500).json({ mensaje: 'Error al eliminar el torneo', error: error.message });
  }
};

// ---- GRUPOS ----

export const crearGrupo = async (req, res) => {
  try {
    const { id } = req.params; // id del torneo
    const { nombre } = req.body;

    if (!nombre) {
      return res.status(400).json({ mensaje: 'El nombre del grupo es obligatorio' });
    }

    const grupo = await torneoModel.crearGrupo({ torneo_id: id, nombre });
    res.status(201).json({ mensaje: 'Grupo creado', grupo });

  } catch (error) {
    console.error(error);
    res.status(500).json({ mensaje: 'Error al crear el grupo', error: error.message });
  }
};

export const obtenerGruposPorTorneo = async (req, res) => {
  try {
    const { id } = req.params;
    const grupos = await torneoModel.listarGruposPorTorneo(id);
    res.json(grupos);
  } catch (error) {
    console.error(error);
    res.status(500).json({ mensaje: 'Error al obtener los grupos', error: error.message });
  }
};