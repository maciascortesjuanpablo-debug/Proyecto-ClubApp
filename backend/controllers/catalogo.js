import { catalogoModel } from '../models/catalogo.js';
import { fallo } from '../utils/helpers.js';

const listar = (consulta, mensaje) => async (req, res) => {
  try {
    res.json(await catalogoModel[consulta]());
  } catch (error) {
    fallo(res, error, mensaje);
  }
};

const obtener = (consulta, mensaje, noEncontrado) => async (req, res) => {
  try {
    const item = await catalogoModel[consulta](req.params.id);
    if (!item) return res.status(404).json({ mensaje: noEncontrado });
    res.json(item);
  } catch (error) {
    fallo(res, error, mensaje);
  }
};

export const listarRoles = listar('listarRoles', 'Error al obtener los roles');
export const obtenerRol = obtener('buscarRolPorId', 'Error al obtener el rol', 'Rol no encontrado');
export const listarDeportes = listar('listarDeportes', 'Error al obtener los deportes');
export const obtenerDeporte = obtener('buscarDeportePorId', 'Error al obtener el deporte', 'Deporte no encontrado');
export const listarFormatos = listar('listarFormatos', 'Error al obtener los formatos');
export const obtenerFormato = obtener('buscarFormatoPorId', 'Error al obtener el formato', 'Formato no encontrado');
