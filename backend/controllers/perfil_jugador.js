import { perfilJugadorModel } from '../models/perfil_jugador.js';
import { eliminarImagen } from '../utils/cloudinaryutils.js';
import { fallo, pick, texto } from '../utils/helpers.js';

// avatar_url y los campos de verificación no se editan aquí: la foto se sube por /foto y la verificación la pone un admin
const EDITABLES = ['posicion', 'pais', 'tipo_jugador'];
const limpiarCampos = (body) => Object.fromEntries(Object.entries(pick(body, EDITABLES)).map(([k, v]) => [k, texto(v, 60)]));

export const crearPerfil = async (req, res) => {
  try {
    const usuario_id = req.usuario.id; // siempre el del token
    if (await perfilJugadorModel.buscarPorUsuarioId(usuario_id)) {
      return res.status(409).json({ mensaje: 'Este usuario ya tiene un perfil creado' });
    }
    const perfil = await perfilJugadorModel.crear({ usuario_id, ...limpiarCampos(req.body) });
    res.status(201).json({ mensaje: 'Perfil creado', perfil });
  } catch (error) {
    fallo(res, error, 'Error al crear el perfil');
  }
};

export const obtenerPerfilPorUsuario = async (req, res) => {
  try {
    const perfil = await perfilJugadorModel.buscarPorUsuarioId(req.params.usuarioId);
    if (!perfil) return res.status(404).json({ mensaje: 'Este usuario no tiene perfil creado todavía' });
    res.json(perfil);
  } catch (error) {
    fallo(res, error, 'Error al obtener el perfil');
  }
};

export const actualizarPerfil = async (req, res) => {
  try {
    const cambios = limpiarCampos(req.body);
    if (!Object.keys(cambios).length) return res.status(400).json({ mensaje: 'No hay campos válidos para actualizar' });
    if (!(await perfilJugadorModel.buscarPorUsuarioId(req.params.usuarioId))) {
      return res.status(404).json({ mensaje: 'Este usuario no tiene perfil creado todavía' });
    }
    res.json({ mensaje: 'Perfil actualizado', perfil: await perfilJugadorModel.actualizar(req.params.usuarioId, cambios) });
  } catch (error) {
    fallo(res, error, 'Error al actualizar el perfil');
  }
};

export const actualizarFotoPerfil = async (req, res) => {
  try {
    const { usuarioId } = req.params;
    if (!req.file) return res.status(400).json({ mensaje: 'No se envió ninguna imagen' });

    const nuevaUrl = req.file.path;
    const existente = await perfilJugadorModel.buscarPorUsuarioId(usuarioId);
    if (!existente) {
      await eliminarImagen(nuevaUrl); // la imagen ya se subió: no la dejamos huérfana
      return res.status(404).json({ mensaje: 'Este usuario no tiene perfil creado todavía' });
    }

    if (existente.avatar_url) await eliminarImagen(existente.avatar_url);
    res.json({ mensaje: 'Foto de perfil actualizada', perfil: await perfilJugadorModel.actualizar(usuarioId, { avatar_url: nuevaUrl }) });
  } catch (error) {
    fallo(res, error, 'Error al actualizar la foto');
  }
};
