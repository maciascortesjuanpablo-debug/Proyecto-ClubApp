import jwt from 'jsonwebtoken';
import crypto from 'crypto';

export const firmarSesion = (u) => jwt.sign({ id: u.id, rol_id: u.rol_id }, process.env.JWT_SECRET, { expiresIn: '7d' });

// Huella del hash actual: el token de recuperación deja de valer cuando la contraseña cambia (un solo uso)
export const huella = (hash) => crypto.createHash('sha256').update(hash ?? '').digest('hex').slice(0, 16);

export const firmarReset = (u, hash) =>
  jwt.sign({ id: u.id, proposito: 'cambiar_password', ph: huella(hash) }, process.env.JWT_SECRET, { expiresIn: '10m' });
