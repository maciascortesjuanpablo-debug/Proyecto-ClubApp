// IDs de la tabla `roles`
export const ROLES = { USUARIO: 1, JUGADOR: 2, ENTRENADOR: 3, ORGANIZADOR: 4, ARBITRO: 5, ADMIN: 6 };
// Roles que una persona puede elegir al registrarse (nunca Admin)
export const ROLES_REGISTRO = [ROLES.JUGADOR, ROLES.ENTRENADOR, ROLES.ORGANIZADOR, ROLES.ARBITRO];

export const MSG_PASSWORD = 'La contraseña debe tener mínimo 8 caracteres, una mayúscula, un número y un carácter especial';

// Respuesta 500 genérica: el detalle solo se registra en el servidor
export const fallo = (res, error, mensaje) => {
  console.error(`${mensaje}:`, error);
  return res.status(500).json({ mensaje });
};

// Resultado de una consulta Supabase: lanza el error o devuelve los datos
export const datos = ({ data, error }) => {
  if (error) throw error;
  return data;
};

// Copia solo los campos permitidos (lista blanca)
export const pick = (obj = {}, campos) =>
  Object.fromEntries(campos.filter((c) => obj[c] !== undefined).map((c) => [c, obj[c]]));

export const esAdmin = (req) => req.usuario?.rol_id === ROLES.ADMIN;
export const esMismoUsuario = (req, id) => String(req.usuario?.id) === String(id);

export const normalizarCorreo = (c) => String(c ?? '').trim().toLowerCase();
export const correoValido = (c) => c.length <= 254 && /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(c);
export const passwordValida = (p) =>
  typeof p === 'string' && p.length >= 8 && p.length <= 72 && /[A-Z]/.test(p) && /\d/.test(p) && /[^A-Za-z0-9]/.test(p);
export const texto = (v, max = 100) => (typeof v === 'string' ? v.trim().slice(0, max) : '');
export const esc = (s) => String(s ?? '').replace(/[&<>"']/g, (c) => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' })[c]);
// Entero dentro de [min, max] o null si no es válido
export const entero = (v, min = 0, max = 1_000_000) => {
  const n = Number(v);
  return v !== '' && v !== null && Number.isInteger(n) && n >= min && n <= max ? n : null;
};
export const FECHA_RE = /^\d{4}-\d{2}-\d{2}$/;
export const HORA_RE = /^([01]\d|2[0-3]):[0-5]\d(:[0-5]\d)?$/;

// Zona horaria para decidir qué es "hoy" y "ahora" (el servidor suele estar en UTC). Se puede cambiar con ZONA_HORARIA en el .env
export const ZONA_HORARIA = process.env.ZONA_HORARIA || 'America/Bogota';

// Fecha (AAAA-MM-DD) y hora (HH:MM) actuales en esa zona
export const ahora = () => {
  const partes = new Intl.DateTimeFormat('en-CA', {
    timeZone: ZONA_HORARIA, year: 'numeric', month: '2-digit', day: '2-digit', hour: '2-digit', minute: '2-digit', hourCycle: 'h23',
  }).formatToParts(new Date());
  const dato = (tipo) => partes.find((p) => p.type === tipo).value;
  return { fecha: `${dato('year')}-${dato('month')}-${dato('day')}`, hora: `${dato('hour')}:${dato('minute')}` };
};
