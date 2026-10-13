import { supabase } from '../config/supabase.js';
import { datos } from '../utils/helpers.js';

const PUBLICO = 'id, nombre, apellido, correo, numero_celular, fecha_nacimiento, ciudad, rol_id, nivel_juego, correo_verificado, activo, creado_en';
const usuarios = () => supabase.from('usuarios');
// ilike con comodines escapados = comparación exacta sin distinguir mayúsculas
const exacto = (correo) => correo.replace(/[\\%_]/g, '\\$&');

export const usuarioModel = {
  async buscarPorCorreo(correo) {
    return datos(await usuarios().select('*').ilike('correo', exacto(correo)).maybeSingle());
  },

  async buscarPorId(id) {
    return datos(await usuarios().select(PUBLICO).eq('id', id).maybeSingle());
  },

  async buscarConHash(id) {
    return datos(await usuarios().select('id, nombre, correo, password_hash').eq('id', id).maybeSingle());
  },

  async listarTodos() {
    return datos(await usuarios()
      .select('id, nombre, apellido, correo, ciudad, rol_id, activo, creado_en')
      .order('creado_en', { ascending: false }));
  },

  async crear(usuario) {
    return datos(await usuarios().insert(usuario).select('id, nombre, apellido, correo, rol_id').single());
  },

  // Usuarios que entran con Google: el correo ya viene verificado y no tienen contraseña
  async crearGoogle({ nombre, apellido, correo, googleId, avatar = null }) {
    return datos(await usuarios()
      .insert({ nombre, apellido, correo, password_hash: null, rol_id: 1, isVerified: true, correo_verificado: true, activo: true, googleId, avatar })
      .select('id, nombre, apellido, correo, rol_id, avatar')
      .single());
  },

  async actualizarUsuario(id, cambios) {
    return datos(await usuarios()
      .update({ ...cambios, actualizado_en: new Date() })
      .eq('id', id)
      .select('id, nombre, apellido, correo, ciudad, numero_celular, rol_id')
      .single());
  },

  async actualizarPassword(id, passwordHash) {
    datos(await usuarios().update({ password_hash: passwordHash, actualizado_en: new Date() }).eq('id', id));
  },

  async eliminar(id) {
    datos(await usuarios().update({ activo: false, actualizado_en: new Date() }).eq('id', id));
  },
};
