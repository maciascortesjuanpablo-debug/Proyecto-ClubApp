import jwt from 'jsonwebtoken';
import { usuarioModel } from '../models/usuario.js';
import { ROLES, esAdmin, esMismoUsuario } from '../utils/helpers.js';

// Verifica que el usuario esté logueado (token de sesión válido)
export const verificarToken = (req, res, next) => {
  const authHeader = req.headers.authorization;

  if (!authHeader?.startsWith('Bearer ')) {
    return res.status(401).json({ mensaje: 'No autorizado, falta el token' });
  }

  try {
    const payload = jwt.verify(authHeader.split(' ')[1], process.env.JWT_SECRET);
    // Los tokens temporales (recuperar contraseña) no sirven como sesión
    if (payload.proposito) throw new Error('token no es de sesión');
    req.usuario = payload; // { id, rol_id }
    next();
  } catch {
    return res.status(401).json({ mensaje: 'Token inválido o expirado' });
  }
};

// Verifica que el usuario tenga uno de los roles permitidos
export const verificarRol = (...rolesPermitidos) => (req, res, next) => {
  if (!req.usuario) return res.status(401).json({ mensaje: 'No autenticado' });
  if (!rolesPermitidos.includes(req.usuario.rol_id)) {
    return res.status(403).json({ mensaje: 'No tienes permisos para realizar esta acción' });
  }
  next();
};


// El recurso es del propio usuario (req.params[param]) o es Admin
export const propietarioOAdmin = (param = 'id') => (req, res, next) =>
  esAdmin(req) || esMismoUsuario(req, req.params[param])
    ? next()
    : res.status(403).json({ mensaje: 'No tienes permisos sobre este recurso' });

// Panel de administración: el token dice que es admin, pero se confirma en la base de datos
// (si lo degradaron o desactivaron, su token ya no sirve aquí aunque no haya vencido)
export const adminVigente = async (req, res, next) => {
  try {
    const usuario = await usuarioModel.buscarPorId(req.usuario.id);
    if (usuario?.activo && usuario.rol_id === ROLES.ADMIN) return next();
    res.status(403).json({ mensaje: 'Solo los administradores pueden entrar aquí' });
  } catch (error) {
    console.error('Verificando administrador:', error);
    res.status(500).json({ mensaje: 'Error al verificar permisos' });
  }
};