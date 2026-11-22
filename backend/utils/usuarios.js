import { usuarioModel } from '../models/usuario.js';

// Devuelve el usuario si existe, está activo y (si se indican roles) tiene uno de ellos; si no, null
export const usuarioConRol = async (id, roles) => {
  if (id === undefined || id === null || id === '') return null;
  try {
    const u = await usuarioModel.buscarPorId(id);
    if (!u || u.activo === false) return null;
    if (roles && !roles.includes(u.rol_id)) return null;
    return u;
  } catch {
    return null; // id con formato inválido
  }
};
