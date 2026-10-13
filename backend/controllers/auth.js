import bcrypt from 'bcrypt';
import { usuarioModel } from '../models/usuario.js';
import { firmarSesion } from '../utils/token.js';
import { ROLES_REGISTRO, MSG_PASSWORD, fallo, normalizarCorreo, correoValido, passwordValida, texto } from '../utils/helpers.js';

// Hash de relleno: compara siempre, exista o no el usuario, para no revelar cuentas por tiempo de respuesta
const HASH_FALSO = bcrypt.hashSync('relleno-sin-uso', 10);

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

    res.json({
      mensaje: 'Inicio de sesión exitoso',
      token: firmarSesion(usuario),
      usuario: {
        id: usuario.id, nombre: usuario.nombre, apellido: usuario.apellido,
        correo: usuario.correo, rol_id: usuario.rol_id,
      },
    });
  } catch (error) {
    fallo(res, error, 'Error al iniciar sesión');
  }
};
