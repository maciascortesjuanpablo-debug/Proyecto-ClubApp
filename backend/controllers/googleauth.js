import { OAuth2Client } from 'google-auth-library';
import { usuarioModel } from '../models/usuario.js';
import { firmarSesion } from '../utils/token.js';
import { fallo, normalizarCorreo } from '../utils/helpers.js';

const client = new OAuth2Client(process.env.GOOGLE_CLIENT_ID);

export const autenticarConGoogle = async (req, res) => {
  const { idToken } = req.body;
  if (typeof idToken !== 'string' || !idToken) {
    return res.status(400).json({ mensaje: 'El idToken de Google es requerido' });
  }

  // 1. Validar el token con Google
  let payload;
  try {
    payload = (await client.verifyIdToken({ idToken, audience: process.env.GOOGLE_CLIENT_ID })).getPayload();
  } catch (error) {
    console.error('Token de Google inválido:', error.message);
    return res.status(401).json({ mensaje: 'Token de Google inválido o expirado' });
  }

  if (!payload.email || !payload.email_verified) {
    return res.status(401).json({ mensaje: 'La cuenta de Google no tiene el correo verificado' });
  }

  try {
    const { sub: googleId, given_name: nombre, family_name: apellido, picture: avatar } = payload;
    const correo = normalizarCorreo(payload.email);

    // 2. ¿Ya existe en Supabase?
    let usuario = await usuarioModel.buscarPorCorreo(correo);
    const existia = !!usuario;

    if (usuario) {
      if (!usuario.activo) return res.status(403).json({ mensaje: 'Esta cuenta está inactiva' });
      if (usuario.googleId && usuario.googleId !== googleId) {
        return res.status(401).json({ mensaje: 'Este correo ya está vinculado a otra cuenta de Google' });
      }

      // Vincula Google si faltaba
      const cambios = {};
      if (!usuario.googleId) cambios.googleId = googleId;
      if (!usuario.avatar && avatar) cambios.avatar = avatar;
      if (!usuario.isVerified) cambios.isVerified = true;
      if (!usuario.correo_verificado) cambios.correo_verificado = true;
      if (Object.keys(cambios).length) await usuarioModel.actualizarUsuario(usuario.id, cambios);
    } else {
      // Google no da celular, fecha de nacimiento ni ciudad: se completan luego en la app
      usuario = await usuarioModel.crearGoogle({ nombre, apellido: apellido || 'N/A', correo, googleId, avatar });
    }

    res.json({
      mensaje: existia ? 'Inicio de sesión exitoso con Google' : 'Registro exitoso con Google',
      token: firmarSesion(usuario),
      usuario: {
        id: usuario.id, nombre: usuario.nombre, apellido: usuario.apellido, correo: usuario.correo,
        rol_id: usuario.rol_id, avatar: usuario.avatar || avatar,
      },
    });
  } catch (error) {
    fallo(res, error, 'Error al autenticar con Google');
  }
};
