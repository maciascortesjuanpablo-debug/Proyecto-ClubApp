import bcrypt from 'bcrypt';
import crypto from 'crypto';
import jwt from 'jsonwebtoken';
import { usuarioModel } from '../models/usuario.js';
import { codigoVerificacionModel } from '../models/verificar_codigo.js';
import { enviarCorreoCodigo, enviarCorreoConfirmacionCambio, generarCodigo, CODIGO_MINUTOS } from '../utils/sendEmail.js';
import { firmarReset, huella } from '../utils/token.js';
import { MSG_PASSWORD, fallo, normalizarCorreo, passwordValida } from '../utils/helpers.js';

const TIPO = 'recuperar_password';
const MAX_INTENTOS = 5;
// Intentos fallidos por usuario (en memoria: se reinicia con el servidor)
const intentos = new Map();

// PASO 1: enviar código al correo
export const enviarCodigo = async (req, res) => {
  try {
    const correo = normalizarCorreo(req.body.correo);
    if (!correo) return res.status(400).json({ mensaje: 'El correo es obligatorio' });

    const usuario = await usuarioModel.buscarPorCorreo(correo);
    // Misma respuesta exista o no el correo (no revela qué cuentas hay)
    if (!usuario || !usuario.activo) return res.json({ mensaje: 'Si el correo existe, se envió un código' });

    await codigoVerificacionModel.invalidarPendientes(usuario.id, TIPO);
    intentos.delete(usuario.id);

    const codigo = generarCodigo();
    await codigoVerificacionModel.crear({
      usuario_id: usuario.id, codigo, tipo: TIPO,
      expira_en: new Date(Date.now() + CODIGO_MINUTOS * 60 * 1000),
    });
    await enviarCorreoCodigo(usuario.correo, usuario.nombre, codigo);

    res.json({ mensaje: 'Si el correo existe, se envió un código' });
  } catch (error) {
    fallo(res, error, 'Error al enviar el código');
  }
};

// PASO 2: verificar el código de 6 dígitos
export const verificarCodigo = async (req, res) => {
  try {
    const correo = normalizarCorreo(req.body.correo);
    const codigo = String(req.body.codigo ?? '').trim();

    if (!correo || !codigo) return res.status(400).json({ mensaje: 'Correo y código son obligatorios' });

    const invalido = () => res.status(400).json({ mensaje: 'Código incorrecto o expirado' });
    if (!/^\d{6}$/.test(codigo)) return invalido();

    const usuario = await usuarioModel.buscarPorCorreo(correo);
    if (!usuario || !usuario.activo) return invalido();

    if ((intentos.get(usuario.id) ?? 0) >= MAX_INTENTOS) {
      await codigoVerificacionModel.invalidarPendientes(usuario.id, TIPO);
      return res.status(429).json({ mensaje: 'Demasiados intentos, solicita un código nuevo' });
    }

    const codigoValido = await codigoVerificacionModel.buscarValido({ usuario_id: usuario.id, codigo });
    if (!codigoValido) {
      intentos.set(usuario.id, (intentos.get(usuario.id) ?? 0) + 1);
      return invalido();
    }

    intentos.delete(usuario.id);
    await codigoVerificacionModel.marcarUsado(codigoValido.id);

    const { password_hash } = await usuarioModel.buscarConHash(usuario.id);
    res.json({ mensaje: 'Código verificado', tokenTemporal: firmarReset(usuario, password_hash) });
  } catch (error) {
    fallo(res, error, 'Error al verificar el código');
  }
};

// PASO 3: cambiar la contraseña (el token temporal vale una sola vez)
export const cambiarPassword = async (req, res) => {
  try {
    const { tokenTemporal, nuevaPassword } = req.body;

    if (!tokenTemporal || !nuevaPassword) {
      return res.status(400).json({ mensaje: 'Token y nueva contraseña son obligatorios' });
    }
    if (!passwordValida(nuevaPassword)) return res.status(400).json({ mensaje: MSG_PASSWORD });

    let payload;
    try {
      payload = jwt.verify(tokenTemporal, process.env.JWT_SECRET);
    } catch {
      return res.status(401).json({ mensaje: 'Token inválido o expirado, solicita un nuevo código' });
    }
    if (payload.proposito !== 'cambiar_password') {
      return res.status(401).json({ mensaje: 'Token no autorizado para esta acción' });
    }

    const usuario = await usuarioModel.buscarConHash(payload.id);
    const huellaActual = Buffer.from(huella(usuario?.password_hash));
    const huellaToken = Buffer.from(String(payload.ph ?? ''));
    if (!usuario || huellaActual.length !== huellaToken.length || !crypto.timingSafeEqual(huellaActual, huellaToken)) {
      return res.status(401).json({ mensaje: 'Este enlace ya fue utilizado, solicita un nuevo código' });
    }

    await usuarioModel.actualizarPassword(usuario.id, await bcrypt.hash(nuevaPassword, 10));
    await enviarCorreoConfirmacionCambio(usuario.correo, usuario.nombre).catch((e) => console.error('Correo de confirmación:', e.message));

    res.json({ mensaje: 'Contraseña actualizada exitosamente' });
  } catch (error) {
    fallo(res, error, 'Error al cambiar la contraseña');
  }
};
