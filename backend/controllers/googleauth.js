import jwt from "jsonwebtoken";
import { OAuth2Client } from "google-auth-library";
import { crearUsuarioGoogle, usuarioModel } from "../models/usuario.js";

const client = new OAuth2Client(process.env.GOOGLE_CLIENT_ID);

export const autenticarConGoogle = async (req, res) => {
  try {
    const { idToken } = req.body;

    if (!idToken) {
      return res.status(400).json({
        error: 'El idToken de Google es requerido'
      });
    }

    // --- DEBUG TEMPORAL: quitar cuando se resuelva el error ---
    console.log('GOOGLE_CLIENT_ID que espera el backend:', process.env.GOOGLE_CLIENT_ID);
    const decoded = jwt.decode(idToken);
    console.log('Audience (aud) real del token:', decoded?.aud);
    console.log('Issuer (iss) del token:', decoded?.iss);
    console.log('Expiración (exp) del token:', decoded?.exp ? new Date(decoded.exp * 1000) : 'N/A');
    // --- FIN DEBUG ---

    // 1. Validar el token con Google
    const ticket = await client.verifyIdToken({
      idToken,
      audience: process.env.GOOGLE_CLIENT_ID
    });

    const payload = ticket.getPayload();
    const {

      sub: googleId,
      email: correo,
      given_name: nombre,
      family_name: apellido,
      picture: avatar
    } = payload;

    // 2. Comprobar si ya existe en Supabase
    const usuarioExistente = await usuarioModel.buscarPorCorreo(correo);

    let usuarioFinal = null;

    if (usuarioExistente) {
      // LOGICA: Ya existe, actualizamos si faltaba vincular Google
      usuarioFinal = usuarioExistente;

      const camposActualizar = {};
      if (!usuarioExistente.googleId) camposActualizar.googleId = googleId;
      if (!usuarioExistente.avatar && avatar) camposActualizar.avatar = avatar;
      if (!usuarioExistente.isVerified) camposActualizar.isVerified = true;
      if (!usuarioExistente.correo_verificado) camposActualizar.correo_verificado = true;
      if (!usuarioExistente.activo) camposActualizar.activo = true;

      if (Object.keys(camposActualizar).length > 0) {
        camposActualizar.actualizado_en = new Date().toISOString();
        await usuarioModel.actualizarUsuario(usuarioExistente.id, camposActualizar);
      }
    } else {
      // LOGICA: Usuario nuevo
      const { data: nuevoUsuario, error: errorCrear } = await crearUsuarioGoogle({
        nombre,
        apellido: apellido || 'N/A', // fallback por si Google no envía family_name

        correo,
        googleId,
        avatar,
        rol_id: 1, // rol por defecto para usuarios registrados vía Google
        isVerified: true,
        correo_verificado: true,
        activo: true
        // numero_celular, fecha_nacimiento y ciudad quedan NULL:
        // Google no los provee; se completan luego dentro de la app.
      });

      if (errorCrear) {
        return res.status(500).json({
          error: 'Error al registrar el usuario en Supabase',
          detalle: errorCrear.message
        });
      }

      usuarioFinal = Array.isArray(nuevoUsuario) ? nuevoUsuario[0] : nuevoUsuario;
    }

    // 3. Generar token de sesión JWT
    const token = jwt.sign(
      { id: usuarioFinal.id, rol_id: usuarioFinal.rol_id },
      process.env.JWT_SECRET,
      { expiresIn: '1d' }
    );

    return res.status(200).json({
      message: usuarioExistente ? 'Inicio de sesión exitoso con Google' : 'Registro exitoso con Google',
      token,
      usuario: {

        id: usuarioFinal.id,
        nombre: usuarioFinal.nombre,
        correo: usuarioFinal.correo,
        rol_id: usuarioFinal.rol_id,
        avatar: usuarioFinal.avatar || avatar
      }
    });

  } catch (error) {
    console.error('Error en autenticarConGoogle:', error);
    return res.status(401).json({
      error: 'Token de Google inválido o expirado'
    });
  }
};