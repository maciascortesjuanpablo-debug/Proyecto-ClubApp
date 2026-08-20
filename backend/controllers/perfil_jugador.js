import { perfilJugadorModel } from '../models/perfil_jugador.js';

export const crearPerfil = async (req, res) => {
  try {
    const { usuario_id, posicion, pais, avatar_url, tipo_jugador } = req.body;

    if (!usuario_id) {
      return res.status(400).json({ mensaje: 'usuario_id es obligatorio' });
    }

    const existente = await perfilJugadorModel.buscarPorUsuarioId(usuario_id);
    if (existente) {
      return res.status(409).json({ mensaje: 'Este usuario ya tiene un perfil creado' });
    }

    const perfil = await perfilJugadorModel.crear({ usuario_id, posicion, pais, avatar_url, tipo_jugador });
    res.status(201).json({ mensaje: 'Perfil creado', perfil });

  } catch (error) {
    console.error(error);
    res.status(500).json({ mensaje: 'Error al crear el perfil', error: error.message });
  }
};

export const obtenerPerfilPorUsuario = async (req, res) => {
  try {
    const { usuarioId } = req.params;
    const perfil = await perfilJugadorModel.buscarPorUsuarioId(usuarioId);

    if (!perfil) {
      return res.status(404).json({ mensaje: 'Este usuario no tiene perfil creado todavía' });
    }

    res.json(perfil);
  } catch (error) {
    console.error(error);
    res.status(500).json({ mensaje: 'Error al obtener el perfil', error: error.message });
  }
};

export const actualizarPerfil = async (req, res) => {
  try {
    const { usuarioId } = req.params;
    const { verificado, distincion, ...datosPermitidos } = req.body; // verificado/distincion los pone un admin, no el propio usuario

    const perfil = await perfilJugadorModel.actualizar(usuarioId, datosPermitidos);
    res.json({ mensaje: 'Perfil actualizado', perfil });

  } catch (error) {
    console.error(error);
    res.status(500).json({ mensaje: 'Error al actualizar el perfil', error: error.message });
  }
};