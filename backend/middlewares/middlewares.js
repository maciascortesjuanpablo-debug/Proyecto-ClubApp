import jwt from 'jsonwebtoken';

// Verifica que el usuario esté logueado (token válido)
export const verificarToken = (req, res, next) => {
  const authHeader = req.headers.authorization;

  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    return res.status(401).json({ mensaje: 'No autorizado, falta el token' });
  }

  const token = authHeader.split(' ')[1];

  try {
    const payload = jwt.verify(token, process.env.JWT_SECRET);
    req.usuario = payload; // { id, rol_id }
    next();
  } catch {
    return res.status(401).json({ mensaje: 'Token inválido o expirado' });
  }
};

// Verifica que el usuario tenga uno de los roles permitidos
export const verificarRol = (...rolesPermitidos) => {
  return (req, res, next) => {
    if (!req.usuario) {
      return res.status(401).json({ mensaje: 'No autenticado' });
    }

    if (!rolesPermitidos.includes(req.usuario.rol_id)) {
      return res.status(403).json({ mensaje: 'No tienes permisos para realizar esta acción' });
    }

    next();
  };
};