import { favoritoModel } from '../models/favoritos.js';
import { fallo } from '../utils/helpers.js';

export const agregarFavorito = async (req, res) => {
  try {
    const { torneo_id, equipo_id } = req.body;
    if (!torneo_id && !equipo_id) {
      return res.status(400).json({ mensaje: 'Debes enviar torneo_id o equipo_id' });
    }
    const nuevo = { usuario_id: req.usuario.id, torneo_id, equipo_id };
    if (await favoritoModel.existe(nuevo)) return res.status(409).json({ mensaje: 'Ya está en tus favoritos' });

    res.status(201).json({ mensaje: 'Agregado a favoritos', favorito: await favoritoModel.agregar(nuevo) });
  } catch (error) {
    fallo(res, error, 'Error al agregar a favoritos');
  }
};

export const obtenerFavoritos = async (req, res) => {
  try {
    res.json(await favoritoModel.listarPorUsuario(req.params.usuarioId));
  } catch (error) {
    fallo(res, error, 'Error al obtener los favoritos');
  }
};

export const eliminarFavorito = async (req, res) => {
  try {
    if (!(await favoritoModel.eliminar(req.params.id, req.usuario.id))) {
      return res.status(404).json({ mensaje: 'Favorito no encontrado' });
    }
    res.json({ mensaje: 'Eliminado de favoritos' });
  } catch (error) {
    fallo(res, error, 'Error al eliminar de favoritos');
  }
};
