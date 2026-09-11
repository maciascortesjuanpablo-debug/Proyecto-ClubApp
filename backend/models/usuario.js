import { supabase } from '../config/supabase.js';


export const usuarioModel = {

  async buscarPorCorreo(correo) {
    const { data, error } = await supabase
      .from('usuarios')
      .select('*')
      .eq('correo', correo)
      .maybeSingle();

    if (error) throw error;
    return data;
  },

  async buscarPorId(id) {
    const { data, error } = await supabase
      .from('usuarios')
      .select('id, nombre, apellido, correo, numero_celular, fecha_nacimiento, ciudad, rol_id, nivel_juego, correo_verificado, activo, creado_en')
      .eq('id', id)
      .maybeSingle();

    if (error) throw error;
    return data;
  },

  async listarTodos() {
    const { data, error } = await supabase
      .from('usuarios')
      .select('id, nombre, apellido, correo, ciudad, rol_id, activo, creado_en')
      .order('creado_en', { ascending: false });


    if (error) throw error;
    return data;
  },

  async crear(usuario) {
    const { data, error } = await supabase
      .from('usuarios')
      .insert(usuario)
      .select('id, nombre, apellido, correo, rol_id')
      .single();

    if (error) throw error;
    return data;
  },

  async actualizarUsuario(id, cambios) {
    const { data, error } = await supabase
      .from('usuarios')
      .update({ ...cambios, actualizado_en: new Date() })
      .eq('id', id)
      .select('id, nombre, apellido, correo, ciudad, numero_celular, rol_id')
      .single();

    if (error) throw error;
    return data;
  },

  async actualizarPassword(id, passwordHash) {
    const { error } = await supabase
      .from('usuarios')
      .update({ password_hash: passwordHash, actualizado_en: new Date() })

      .eq('id', id);

    if (error) throw error;
  },

  async marcarCorreoVerificado(id) {
    const { error } = await supabase
      .from('usuarios')
      .update({ correo_verificado: true })
      .eq('id', id);

    if (error) throw error;
  },

  async eliminar(id) {
    const { error } = await supabase
      .from('usuarios')
      .update({ activo: false, actualizado_en: new Date() })
      .eq('id', id);

    if (error) throw error;
  }
};

// 2. Función específica para los usuarios autenticados con Google
export const crearUsuarioGoogle = async ({ nombre, apellido, correo, googleId, avatar = null, rol_id = 'cliente' }) => {
  const { data, error } = await supabase
    .from('usuarios')
    .insert({
      nombre,
      apellido,
      correo,

      password_hash: null,              // No requiere contraseña
      rol_id,
      isVerified: true,            // Google ya validó este correo
      googleId,
      avatar,
      codigoVerificacion: null,
      codigoVerificacionExpiracion: null
    })
    .select('id, nombre, apellido, correo, rol_id, avatar')
    .single();

  return { data, error };
};