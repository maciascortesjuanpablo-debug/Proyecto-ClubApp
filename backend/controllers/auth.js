import bcrypt from 'bcrypt';
import jwt from 'jsonwebtoken';
import { usuarioModel } from '../models/usuario.js';

export const registrar = async (req, res) => {
  try {
    const { nombre, apellido, correo, numero_celular, fecha_nacimiento, ciudad, password } = req.body;

    if (!nombre || !apellido || !correo || !password) {
      return res.status(400).json({ mensaje: 'Faltan campos obligatorios' });
    }

    const existente = await usuarioModel.buscarPorCorreo(correo);
    if (existente) {
      return res.status(409).json({ mensaje: 'Ya existe una cuenta con ese correo' });
    }

    const passwordHash = await bcrypt.hash(password, 10);

    const nuevoUsuario = await usuarioModel.crear({
      nombre, apellido, correo, numero_celular, fecha_nacimiento, ciudad,
      password_hash: passwordHash
    });

    res.status(201).json({ mensaje: 'Cuenta creada exitosamente', usuario: nuevoUsuario });

  } catch (error) {
    console.error(error);
    res.status(500).json({ mensaje: 'Error al registrar usuario', error: error.message });
  }
};

export const iniciarSesion = async (req, res) => {
  try {
    const { correo, password } = req.body;

    if (!correo || !password) {
      return res.status(400).json({ mensaje: 'Correo y contraseña son obligatorios' });
    }

    const usuario = await usuarioModel.buscarPorCorreo(correo);
    if (!usuario) {
      return res.status(401).json({ mensaje: 'Correo o contraseña incorrectos' });
    }

    if (!usuario.activo) {
      return res.status(403).json({ mensaje: 'Esta cuenta está inactiva' });
    }

    const passwordValido = await bcrypt.compare(password, usuario.password_hash);
    if (!passwordValido) {
      return res.status(401).json({ mensaje: 'Correo o contraseña incorrectos' });
    }

    const token = jwt.sign(
      { id: usuario.id, rol_id: usuario.rol_id },
      process.env.JWT_SECRET,
      { expiresIn: '7d' }
    );

    res.json({
      mensaje: 'Inicio de sesión exitoso',
      token,
      usuario: {
        id: usuario.id, nombre: usuario.nombre, apellido: usuario.apellido,
        correo: usuario.correo, rol_id: usuario.rol_id
      }
    });

  } catch (error) {
    console.error(error);
    res.status(500).json({ mensaje: 'Error al iniciar sesión', error: error.message });
  }
};