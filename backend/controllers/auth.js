import bcrypt from 'bcrypt';
import jwt from 'jsonwebtoken';
import { usuarioModel } from '../models/usuario.js';
import { codigoVerificacionModel } from '../models/verificar_codigo.js';
import { firmarSesion } from '../utils/token.js';
import { enviarCorreoCodigo, generarCodigo, CODIGO_MINUTOS } from '../utils/sendEmail.js';
import { ROLES_REGISTRO, MSG_PASSWORD, fallo, normalizarCorreo, correoValido, passwordValida, texto } from '../utils/helpers.js';

// Hash de relleno: compara siempre, exista o no el usuario, para no revelar cuentas por tiempo de respuesta
const HASH_FALSO = bcrypt.hashSync('relleno-sin-uso', 10);

const TIPO_2FA = 'login_2fa';
const MAX_INTENTOS = 5;
const intentos = new Map(); // intentos fallidos por usuario (en memoria: se reinicia con el servidor)

// El segundo paso está activo salvo que en el .env pongas DOS_PASOS=false
const dosPasosActivo = () => process.env.DOS_PASOS !== 'false';
const enmascarar = (c) => c.replace(/^(.{1,2})[^@]*/, (_, p) => `${p}**`); // juan@gmail.com -> ju**@gmail.com
const usuarioPublico = (u) => ({ id: u.id, nombre: u.nombre, apellido: u.apellido, correo: u.correo, rol_id: u.rol_id });
const respuestaSesion = (u) => ({ mensaje: 'Inicio de sesión exitoso', token: firmarSesion(u), usuario: usuarioPublico(u) });

// Genera y envía el código; devuelve el token del desafío que la app usa para verificar o reenviar
const enviarDesafio = async (usuario) => {
  await codigoVerificacionModel.invalidarPendientes(usuario.id, TIPO_2FA);
  intentos.delete(usuario.id);
  const codigo = generarCodigo();
  await codigoVerificacionModel.crear({
    usuario_id: usuario.id, codigo, tipo: TIPO_2FA,
    expira_en: new Date(Date.now() + CODIGO_MINUTOS * 60 * 1000),
  });
  await enviarCorreoCodigo(usuario.correo, usuario.nombre, codigo, 'iniciar sesión en tu cuenta');
  const tokenDesafio = jwt.sign({ id: usuario.id, proposito: '2fa' }, process.env.JWT_SECRET, { expiresIn: '15m' });
  return { requiere2fa: true, mensaje: 'Te enviamos un código de verificación', tokenDesafio, correo: enmascarar(usuario.correo) };
};

const idDelDesafio = (token) => {
  try {
    const p = jwt.verify(token, process.env.JWT_SECRET);
    return p.proposito === '2fa' ? p.id : null;
  } catch {
    return null;
  }
};

export const registrar = async (req, res) => {
  try {
    const { numero_celular, fecha_nacimiento, ciudad, password, rol_id, nivel_juego } = req.body;
    const nombre = texto(req.body.nombre, 60);
    const apellido = texto(req.body.apellido, 60);
    const correo = normalizarCorreo(req.body.correo);

    if (!nombre || !apellido || !correo || !password) {
      return res.status(400).json({ mensaje: 'Faltan campos obligatorios' });
    }
    if (!correoValido(correo)) return res.status(400).json({ mensaje: 'El correo no es válido' });
    if (!passwordValida(password)) return res.status(400).json({ mensaje: MSG_PASSWORD });
    if (fecha_nacimiento && !/^\d{4}-\d{2}-\d{2}$/.test(fecha_nacimiento)) {
      return res.status(400).json({ mensaje: 'La fecha de nacimiento debe tener formato AAAA-MM-DD' });
    }
    if (rol_id !== undefined && !ROLES_REGISTRO.includes(Number(rol_id))) {
      return res.status(400).json({ mensaje: 'Rol no permitido' });
    }

    if (await usuarioModel.buscarPorCorreo(correo)) {
      return res.status(409).json({ mensaje: 'Ya existe una cuenta con ese correo' });
    }

    const nuevoUsuario = await usuarioModel.crear({
      nombre, apellido, correo,
      numero_celular: texto(numero_celular, 20) || null,
      fecha_nacimiento: fecha_nacimiento || null,
      ciudad: texto(ciudad) || null,
      password_hash: await bcrypt.hash(password, 10),
      ...(rol_id !== undefined && { rol_id: Number(rol_id) }),
      ...(nivel_juego && { nivel_juego: texto(nivel_juego, 30) }),
    });

    res.status(201).json({ mensaje: 'Cuenta creada exitosamente', usuario: nuevoUsuario });
  } catch (error) {
    fallo(res, error, 'Error al registrar usuario');
  }
};

// PASO 1: contraseña correcta -> manda el código al correo (la sesión se abre en verificarDosPasos)
export const iniciarSesion = async (req, res) => {
  try {
    const correo = normalizarCorreo(req.body.correo);
    const { password } = req.body;

    if (!correo || typeof password !== 'string' || !password) {
      return res.status(400).json({ mensaje: 'Correo y contraseña son obligatorios' });
    }

    const usuario = await usuarioModel.buscarPorCorreo(correo);
    // Cuentas creadas con Google no tienen password_hash: nunca pasan por aquí
    const passwordValido = await bcrypt.compare(password, usuario?.password_hash ?? HASH_FALSO);

    if (!usuario?.password_hash || !passwordValido) {
      return res.status(401).json({ mensaje: 'Correo o contraseña incorrectos' });
    }
    if (!usuario.activo) {
      return res.status(403).json({ mensaje: 'Esta cuenta está inactiva' });
    }

    res.json(dosPasosActivo() ? await enviarDesafio(usuario) : respuestaSesion(usuario));
  } catch (error) {
    fallo(res, error, 'Error al iniciar sesión');
  }
};

// PASO 2: valida el código de 6 dígitos y abre la sesión
export const verificarDosPasos = async (req, res) => {
  try {
    const id = idDelDesafio(req.body.tokenDesafio);
    const codigo = String(req.body.codigo ?? '').trim();

    if (!id) return res.status(401).json({ mensaje: 'La verificación expiró, inicia sesión de nuevo' });

    const invalido = () => res.status(400).json({ mensaje: 'Código incorrecto o expirado' });
    if (!/^\d{6}$/.test(codigo)) return invalido();

    if ((intentos.get(id) ?? 0) >= MAX_INTENTOS) {
      await codigoVerificacionModel.invalidarPendientes(id, TIPO_2FA);
      return res.status(429).json({ mensaje: 'Demasiados intentos, solicita un código nuevo' });
    }

    const valido = await codigoVerificacionModel.buscarValido({ usuario_id: id, codigo, tipo: TIPO_2FA });
    if (!valido) {
      intentos.set(id, (intentos.get(id) ?? 0) + 1);
      return invalido();
    }

    intentos.delete(id);
    await codigoVerificacionModel.marcarUsado(valido.id);

    const usuario = await usuarioModel.buscarConHash(id);
    if (!usuario || usuario.activo === false) return res.status(403).json({ mensaje: 'Esta cuenta está inactiva' });

    res.json(respuestaSesion(usuario));
  } catch (error) {
    fallo(res, error, 'Error al verificar el código');
  }
};

export const reenviarDosPasos = async (req, res) => {
  try {
    const id = idDelDesafio(req.body.tokenDesafio);
    const usuario = id && (await usuarioModel.buscarConHash(id));
    if (!usuario) return res.status(401).json({ mensaje: 'La verificación expiró, inicia sesión de nuevo' });

    await enviarDesafio(usuario);
    res.json({ mensaje: 'Código reenviado' });
  } catch (error) {
    fallo(res, error, 'No se pudo reenviar el código');
  }
};