import { usuarioModel } from '../models/usuario.js';
import { fallo, pick } from '../utils/helpers.js';

const EDITABLES = ['nombre', 'apellido', 'numero_celular', 'fecha_nacimiento', 'ciudad', 'nivel_juego'];

export const obtenerUsuarios = async (req, res) => {
  try {
    res.json(await usuarioModel.listarTodos());
  } catch (error) {
    fallo(res, error, 'Error al obtener usuarios');
  }
};

export const obtenerUsuarioPorId = async (req, res) => {
  try {
    const usuario = await usuarioModel.buscarPorId(req.params.id);
    if (!usuario) return res.status(404).json({ mensaje: 'Usuario no encontrado' });
    res.json(usuario);
  } catch (error) {
    fallo(res, error, 'Error al obtener el usuario');
  }
};

export const actualizarUsuario = async (req, res) => {
  try {
    const cambios = pick(req.body, EDITABLES); // lista blanca: rol, correo, verificación, etc. no se tocan aquí
    if (!Object.keys(cambios).length) return res.status(400).json({ mensaje: 'No hay campos válidos para actualizar' });

    res.json({ mensaje: 'Usuario actualizado', usuario: await usuarioModel.actualizarUsuario(req.params.id, cambios) });
  } catch (error) {
    fallo(res, error, 'Error al actualizar el usuario');
  }
};

export const eliminarUsuario = async (req, res) => {
  try {
    await usuarioModel.eliminar(req.params.id);
    res.json({ mensaje: 'Usuario desactivado exitosamente' });
  } catch (error) {
    fallo(res, error, 'Error al eliminar el usuario');
  }
};
