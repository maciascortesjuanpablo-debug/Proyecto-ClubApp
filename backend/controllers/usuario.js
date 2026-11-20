import bcrypt from 'bcrypt';
import { usuarioModel } from '../models/usuario.js';
import { enviarCorreoConfirmacionCambio } from '../utils/sendEmail.js';
import { respuestaSesion } from '../utils/token.js';
import { VERSION_POLITICA, edadDe, estadoConsentimiento } from '../utils/consentimiento.js';
import { DIAS_PURGA } from '../utils/purga.js';
import { FECHA_RE, MSG_PASSWORD, ROLES, ROLES_REGISTRO, fallo, passwordValida, pick, texto } from '../utils/helpers.js';

const EDITABLES = ['nombre', 'apellido', 'numero_celular', 'fecha_nacimiento', 'ciudad', 'nivel_juego'];

// Limpia y valida en el lugar los campos editables de un usuario. Devuelve el mensaje de error o null.
export const limpiarCambiosUsuario = (cambios) => {
  for (const campo of ['nombre', 'apellido']) {
    if (campo in cambios && !(cambios[campo] = texto(cambios[campo], 60))) return `El campo ${campo} no puede estar vacío`;
  }
  if ('numero_celular' in cambios) cambios.numero_celular = texto(cambios.numero_celular, 20) || null;
  if ('ciudad' in cambios) cambios.ciudad = texto(cambios.ciudad) || null;
  if ('nivel_juego' in cambios) cambios.nivel_juego = texto(cambios.nivel_juego, 30) || null;
  if ('fecha_nacimiento' in cambios) {
    if (cambios.fecha_nacimiento && !FECHA_RE.test(cambios.fecha_nacimiento)) return 'La fecha de nacimiento debe tener formato AAAA-MM-DD';
    cambios.fecha_nacimiento ||= null;
  }
  return null;
};

export const obtenerUsuarios = async (req, res) => {
  try {
    res.json(await usuarioModel.listarTodos());
  } catch (error) {
    fallo(res, error, 'Error al obtener usuarios');
  }
};

export const obtenerUsuarioPorId = async (req, res) => {

  try {
    const usuario = await usuarioModel.buscarPorId(req.params.id);
    if (!usuario) return res.status(404).json({ mensaje: 'Usuario no encontrado' });
    res.json(usuario);
  } catch (error) {
    fallo(res, error, 'Error al obtener el usuario');
  }
};

export const actualizarUsuario = async (req, res) => {
  try {
    const cambios = pick(req.body, EDITABLES); // lista blanca: rol, correo, verificación, etc. no se tocan aquí
    if (!Object.keys(cambios).length) return res.status(400).json({ mensaje: 'No hay campos válidos para actualizar' });

    const errorDatos = limpiarCambiosUsuario(cambios);
    if (errorDatos) return res.status(400).json({ mensaje: errorDatos });

    res.json({ mensaje: 'Usuario actualizado', usuario: await usuarioModel.actualizarUsuario(req.params.id, cambios) });
  } catch (error) {
    fallo(res, error, 'Error al actualizar el usuario');
  }
};

// Desactiva la cuenta ya y programa el borrado de los datos personales (ver utils/purga.js)
export const eliminarUsuario = async (req, res) => {
  try {
    await usuarioModel.programarEliminacion(req.params.id, new Date(Date.now() + DIAS_PURGA * 24 * 3600 * 1000));
    res.json({ mensaje: `Cuenta desactivada. Tus datos personales se eliminarán en ${DIAS_PURGA} días` });
  } catch (error) {
    fallo(res, error, 'Error al eliminar el usuario');
  }
};


// ¿Esta cuenta tiene la autorización vigente? (la app lo consulta al abrir con una sesión guardada)
export const consultarConsentimiento = async (req, res) => {
  res.json(await estadoConsentimiento(req.usuario.id));
};

// Registra la aceptación de los términos y la política (cuentas de Google y cuentas anteriores a esta versión).
// Si no hay fecha de nacimiento se pide aquí; un menor de 18 años necesita la autorización de su acudiente.
export const aceptarTerminos = async (req, res) => {
  try {
    if (req.body.acepta_terminos !== true) return res.status(400).json({ mensaje: 'Debes aceptar los términos y la política de privacidad' });
    if (req.body.version_politica !== VERSION_POLITICA) return res.status(400).json({ mensaje: 'Los términos cambiaron: actualiza la aplicación e inténtalo de nuevo' });

    const actual = await usuarioModel.consentimiento(req.usuario.id);
    const cambios = {};
    let fecha = actual?.fecha_nacimiento ? String(actual.fecha_nacimiento).slice(0, 10) : null;
    if (edadDe(fecha) === null) {
      fecha = req.body.fecha_nacimiento;
      if (edadDe(fecha) === null) return res.status(400).json({ mensaje: 'La fecha de nacimiento es obligatoria y debe ser válida' });
      cambios.fecha_nacimiento = fecha;
    }
    const menor = edadDe(fecha) < 18;
    if (menor && req.body.autorizacion_acudiente !== true) {
      return res.status(400).json({ mensaje: 'Los menores de 18 años necesitan la autorización de su padre, madre o representante legal' });
    }

    await usuarioModel.registrarAceptacion(req.usuario.id, {
      ...cambios, acepto_terminos_en: new Date().toISOString(), version_politica: VERSION_POLITICA, autorizacion_acudiente: menor,
    });
    res.json({ mensaje: 'Aceptación registrada' });
  } catch (error) {
    fallo(res, error, 'Error al registrar la aceptación');
  }
};

// Cambiar la contraseña estando logueado: exige la actual
export const cambiarPassword = async (req, res) => {
  try {
    const { passwordActual, nuevaPassword } = req.body;
    if (typeof passwordActual !== 'string' || !passwordActual || !nuevaPassword) {
      return res.status(400).json({ mensaje: 'La contraseña actual y la nueva son obligatorias' });
    }
    if (!passwordValida(nuevaPassword)) return res.status(400).json({ mensaje: MSG_PASSWORD });
    if (passwordActual === nuevaPassword) return res.status(400).json({ mensaje: 'La nueva contraseña debe ser distinta a la actual' });

    const usuario = await usuarioModel.buscarConHash(req.usuario.id);
    if (!usuario?.password_hash) {
      return res.status(400).json({ mensaje: 'Tu cuenta entra con Google y no tiene contraseña que cambiar' });
    }
    // 400 y no 401: un 401 haría que la app cierre la sesión
    if (!(await bcrypt.compare(passwordActual, usuario.password_hash))) {
      return res.status(400).json({ mensaje: 'La contraseña actual es incorrecta' });
    }

    await usuarioModel.actualizarPassword(usuario.id, await bcrypt.hash(nuevaPassword, 10));
    await enviarCorreoConfirmacionCambio(usuario.correo, usuario.nombre).catch((e) => console.error('Correo de confirmación:', e.message));

    res.json({ mensaje: 'Contraseña actualizada exitosamente' });
  } catch (error) {
    fallo(res, error, 'Error al cambiar la contraseña');
  }
};

// Quien entró con Google nace como "Usuario": puede elegir su rol UNA vez (como en el registro normal, nunca Admin).
// Devuelve una sesión nueva porque el rol viaja dentro del token.
export const elegirRol = async (req, res) => {
  try {

    const rolId = Number(req.body.rol_id);
    if (!ROLES_REGISTRO.includes(rolId)) return res.status(400).json({ mensaje: 'Rol no permitido' });

    const usuario = await usuarioModel.buscarPorId(req.usuario.id);
    if (!usuario?.activo) return res.status(403).json({ mensaje: 'Esta cuenta está inactiva' });
    if (usuario.rol_id !== ROLES.USUARIO) {
      return res.status(409).json({ mensaje: 'Tu rol ya está definido. Para cambiarlo contacta a un administrador' });
    }

    const actualizado = await usuarioModel.actualizarUsuario(usuario.id, { rol_id: rolId });
    res.json(respuestaSesion(actualizado, 'Rol actualizado'));
  } catch (error) {
    fallo(res, error, 'Error al elegir el rol');
  }
};