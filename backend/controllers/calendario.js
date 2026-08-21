import { calendarioModel } from '../models/calendario.js';

export const crearSede = async (req, res) => {
  try {
    const { nombre, direccion, ciudad } = req.body;
    if (!nombre) return res.status(400).json({ mensaje: 'El nombre de la sede es obligatorio' });
    const sede = await calendarioModel.crearSede({ nombre, direccion, ciudad });
    res.status(201).json({ mensaje: 'Sede creada', sede });
  } catch (error) {
    console.error(error);
    res.status(500).json({ mensaje: 'Error al crear la sede', error: error.message });
  }
};

export const obtenerSedes = async (req, res) => {
  try {
    res.json(await calendarioModel.listarSedes());
  } catch (error) {
    console.error(error);
    res.status(500).json({ mensaje: 'Error al obtener las sedes', error: error.message });
  }
};

export const crearEvento = async (req, res) => {
  try {
    const { torneo_id, tipo, equipo_local_id, equipo_visitante_id, fecha, hora, lugar_id } = req.body;
    if (!torneo_id || !tipo || !fecha || !hora) {
      return res.status(400).json({ mensaje: 'torneo_id, tipo, fecha y hora son obligatorios' });
    }
    const evento = await calendarioModel.crearEvento({ torneo_id, tipo, equipo_local_id, equipo_visitante_id, fecha, hora, lugar_id });
    res.status(201).json({ mensaje: 'Evento creado', evento });
  } catch (error) {
    console.error(error);
    res.status(500).json({ mensaje: 'Error al crear el evento', error: error.message });
  }
};

export const obtenerEventosPorTorneo = async (req, res) => {
  try {
    res.json(await calendarioModel.listarPorTorneo(req.params.torneoId));
  } catch (error) {
    console.error(error);
    res.status(500).json({ mensaje: 'Error al obtener los eventos', error: error.message });
  }
};

export const obtenerEventoPorId = async (req, res) => {
  try {
    const evento = await calendarioModel.buscarPorId(req.params.id);
    if (!evento) return res.status(404).json({ mensaje: 'Evento no encontrado' });
    res.json(evento);
  } catch (error) {
    console.error(error);
    res.status(500).json({ mensaje: 'Error al obtener el evento', error: error.message });
  }
};

export const actualizarEvento = async (req, res) => {
  try {
    const evento = await calendarioModel.actualizar(req.params.id, req.body);
    res.json({ mensaje: 'Evento actualizado', evento });
  } catch (error) {
    console.error(error);
    res.status(500).json({ mensaje: 'Error al actualizar el evento', error: error.message });
  }
};

export const eliminarEvento = async (req, res) => {
  try {
    await calendarioModel.eliminar(req.params.id);
    res.json({ mensaje: 'Evento eliminado' });
  } catch (error) {
    console.error(error);
    res.status(500).json({ mensaje: 'Error al eliminar el evento', error: error.message });
  }
};

export const asignarArbitro = async (req, res) => {
  try {
    const { usuario_id, rol_arbitraje } = req.body;
    if (!usuario_id) return res.status(400).json({ mensaje: 'usuario_id es obligatorio' });
    const arbitro = await calendarioModel.asignarArbitro({ evento_id: req.params.id, usuario_id, rol_arbitraje: rol_arbitraje || 'Principal' });
    res.status(201).json({ mensaje: 'Árbitro asignado', arbitro });
  } catch (error) {
    console.error(error);
    res.status(500).json({ mensaje: 'Error al asignar el árbitro', error: error.message });
  }
};

export const obtenerArbitrosPorEvento = async (req, res) => {
  try {
    res.json(await calendarioModel.listarArbitrosPorEvento(req.params.id));
  } catch (error) {
    console.error(error);
    res.status(500).json({ mensaje: 'Error al obtener los árbitros', error: error.message });
  }
};