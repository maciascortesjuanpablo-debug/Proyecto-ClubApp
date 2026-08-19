import { usuarioModel } from '../models/usuario.model.js';

export const obtenerUsuarios = async (req, res) => {
  try {
    const usuarios = await usuarioModel.listarTodos();
    res.json(usuarios);
  } catch (error) {
    console.error(error);
    res.status(500).json({ mensaje: 'Error al obtener usuarios', error: error.message });
  }
};

export const obtenerUsuarioPorId = async (req, res) => {
  try {
    const { id } = req.params;
    const usuario = await usuarioModel.buscarPorId(id);

    if (!usuario) {
      return res.status(404).json({ mensaje: 'Usuario no encontrado' });
    }

    res.json(usuario);
  } catch (error) {
    console.error(error);
    res.status(500).json({ mensaje: 'Error al obtener el usuario', error: error.message });
  }
};

export const actualizarUsuario = async (req, res) => {
  try {
    const { id } = req.params;

    // Bloqueamos campos sensibles que no deben cambiarse por esta ruta
    const { password, password_hash, rol_id, correo_verificado, activo, correo, ...datosPermitidos } = req.body;

    const usuarioActualizado = await usuarioModel.actualizar(id, datosPermitidos);
    res.json({ mensaje: 'Usuario actualizado', usuario: usuarioActualizado });

  } catch (error) {
    console.error(error);
    res.status(500).json({ mensaje: 'Error al actualizar el usuario', error: error.message });
  }
};

export const eliminarUsuario = async (req, res) => {
  try {
    const { id } = req.params;
    await usuarioModel.eliminar(id);
    res.json({ mensaje: 'Usuario desactivado exitosamente' });
  } catch (error) {
    console.error(error);
    res.status(500).json({ mensaje: 'Error al eliminar el usuario', error: error.message });
  }
};