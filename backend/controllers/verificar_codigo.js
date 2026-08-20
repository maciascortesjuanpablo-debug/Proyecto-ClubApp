import bcrypt from 'bcrypt';
import jwt from 'jsonwebtoken';
import { usuarioModel } from '../models/usuario.js';
import { codigoVerificacionModel } from '../models/verificar_codigo.js';
import { enviarCorreoCodigo, enviarCorreoConfirmacionCambio, generarCodigo } from '../utils/sendEmail.js';

// PASO 1: enviar código al correo
export const enviarCodigo = async (req, res) => {
  try {
    const { correo } = req.body;

    if (!correo) {
      return res.status(400).json({ mensaje: 'El correo es obligatorio' });
    }

    const usuario = await usuarioModel.buscarPorCorreo(correo);
    if (!usuario) {
      return res.json({ mensaje: 'Si el correo existe, se envió un código' });
    }

    const codigo = generarCodigo();

    await codigoVerificacionModel.crear({
      usuario_id: usuario.id,
      codigo,
      tipo: 'recuperar_password',
      expira_en: new Date(Date.now() + 2 * 60 * 1000)
    });

    await enviarCorreoCodigo(usuario.correo, usuario.nombre, codigo);

    res.json({ mensaje: 'Código enviado a tu correo' });

  } catch (error) {
    console.error(error);
    res.status(500).json({ mensaje: 'Error al enviar el código', error: error.message });
  }
};

// PASO 2: verificar el código de 6 dígitos
export const verificarCodigo = async (req, res) => {
  try {
    const { correo, codigo } = req.body;

    if (!correo || !codigo) {
      return res.status(400).json({ mensaje: 'Correo y código son obligatorios' });
    }

    const usuario = await usuarioModel.buscarPorCorreo(correo);
    if (!usuario) {
      return res.status(404).json({ mensaje: 'Usuario no encontrado' });
    }

    const codigoValido = await codigoVerificacionModel.buscarValido({
      usuario_id: usuario.id,
      codigo
    });

    if (!codigoValido) {
      return res.status(400).json({ mensaje: 'Código incorrecto o expirado' });
    }

    await codigoVerificacionModel.marcarUsado(codigoValido.id);

    const tokenTemporal = jwt.sign(
      { id: usuario.id, proposito: 'cambiar_password' },
      process.env.JWT_SECRET,
      { expiresIn: '10m' }
    );

    res.json({ mensaje: 'Código verificado', tokenTemporal });

  } catch (error) {
    console.error(error);
    res.status(500).json({ mensaje: 'Error al verificar el código', error: error.message });
  }
};

// PASO 3: cambiar la contraseña
export const cambiarPassword = async (req, res) => {
  try {
    const { tokenTemporal, nuevaPassword } = req.body;

    if (!tokenTemporal || !nuevaPassword) {
      return res.status(400).json({ mensaje: 'Token y nueva contraseña son obligatorios' });
    }

    if (nuevaPassword.length < 8) {
      return res.status(400).json({ mensaje: 'La contraseña debe tener mínimo 8 caracteres' });
    }

    let payload;
    try {
      payload = jwt.verify(tokenTemporal, process.env.JWT_SECRET);
    } catch {
      return res.status(401).json({ mensaje: 'Token inválido o expirado, solicita un nuevo código' });
    }

    if (payload.proposito !== 'cambiar_password') {
      return res.status(401).json({ mensaje: 'Token no autorizado para esta acción' });
    }

    const passwordHash = await bcrypt.hash(nuevaPassword, 10);
    await usuarioModel.actualizarPassword(payload.id, passwordHash);

    const usuario = await usuarioModel.buscarPorId(payload.id);
    await enviarCorreoConfirmacionCambio(usuario.correo, usuario.nombre);

    res.json({ mensaje: 'Contraseña actualizada exitosamente' });

  } catch (error) {
    console.error(error);
    res.status(500).json({ mensaje: 'Error al cambiar la contraseña', error: error.message });
  }
};