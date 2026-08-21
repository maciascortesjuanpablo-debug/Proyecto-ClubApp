import { favoritoModel } from '../models/favoritos.js';

export const agregarFavorito = async (req, res) => {
  try {
    const { torneo_id, equipo_id } = req.body;
    if (!torneo_id && !equipo_id) {
      return res.status(400).json({ mensaje: 'Debes enviar torneo_id o equipo_id' });
    }
    const favorito = await favoritoModel.agregar({ usuario_id: req.usuario.id, torneo_id, equipo_id });
    res.status(201).json({ mensaje: 'Agregado a favoritos', favorito });
  } catch (error) {
    console.error(error);
    res.status(500).json({ mensaje: 'Error al agregar a favoritos', error: error.message });
  }
};

export const obtenerFavoritos = async (req, res) => {
  try {
    res.json(await favoritoModel.listarPorUsuario(req.params.usuarioId));
  } catch (error) {
    console.error(error);
    res.status(500).json({ mensaje: 'Error al obtener los favoritos', error: error.message });
  }
};

export const eliminarFavorito = async (req, res) => {
  try {
    await favoritoModel.eliminar(req.params.id);
    res.json({ mensaje: 'Eliminado de favoritos' });
  } catch (error) {
    console.error(error);
    res.status(500).json({ mensaje: 'Error al eliminar de favoritos', error: error.message });
  }
};