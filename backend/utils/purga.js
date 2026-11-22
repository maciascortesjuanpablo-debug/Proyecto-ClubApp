import { supabase } from '../config/supabase.js';
import { eliminarImagen } from './cloudinaryutils.js';
import { datos } from './helpers.js';

// Días entre que la persona elimina su cuenta y se borran sus datos personales (ver Política de Privacidad, numeral 10)
export const DIAS_PURGA = 30;

// Datos que cuelgan de la persona y se borran del todo (tabla, columna)
const DEPENDENCIAS = [
  ['favoritos', 'usuario_id'], ['notificaciones', 'usuario_id'], ['perfil_jugador', 'usuario_id'],
  ['equipo_jugadores', 'usuario_id'], ['equipo_staff', 'usuario_id'], ['partido_arbitros', 'usuario_id'],
  ['codigos_verificacion', 'usuario_id'], ['invitaciones_equipo', 'usuario_id'], ['invitaciones_equipo', 'invitado_por'],
  ['scout_ai_recomendaciones', 'solicitado_por'], ['scout_ai_reportes', 'solicitado_por'], ['scout_ai_reportes', 'usuario_id'],
];

// Un paso que falle (tabla inexistente, etc.) no impide los demás
const intentar = async (etiqueta, fn) => {
  try {
    await fn();
  } catch (error) {
    console.warn(`[PURGA] ${etiqueta}: ${error.message}`);
  }
};

// Borra los datos personales y deja la fila anonimizada: las estadísticas y resultados de partidos
// ya jugados se conservan sin nombre, porque forman parte del historial de otras personas.
export const anonimizarUsuario = async (id) => {
  await intentar('foto de perfil', async () => {
    const perfiles = datos(await supabase.from('perfil_jugador').select('avatar_url').eq('usuario_id', id));
    for (const p of perfiles) if (p.avatar_url) await eliminarImagen(p.avatar_url);
  });

  await intentar('conversaciones de Scout AI', async () => {
    const conversaciones = datos(await supabase.from('scout_ai_conversaciones').select('id').eq('usuario_id', id)).map((c) => c.id);
    if (!conversaciones.length) return;
    datos(await supabase.from('scout_ai_recomendaciones').update({ conversacion_id: null }).in('conversacion_id', conversaciones));
    datos(await supabase.from('scout_ai_mensajes').delete().in('conversacion_id', conversaciones));
    datos(await supabase.from('scout_ai_conversaciones').delete().in('id', conversaciones));
  });

  for (const [tabla, columna] of DEPENDENCIAS) {
    await intentar(`${tabla}.${columna}`, async () => datos(await supabase.from(tabla).delete().eq(columna, id)));
  }

  datos(await supabase.from('usuarios').update({
    nombre: 'Usuario', apellido: 'eliminado', correo: `eliminado-${id}@eliminado.invalid`,
    numero_celular: null, fecha_nacimiento: null, ciudad: null, nivel_juego: null,
    password_hash: null, googleId: null, avatar: null,
    activo: false, correo_verificado: false, isVerified: false,
    anonimizado_en: new Date().toISOString(),
  }).eq('id', id));
};

// Anonimiza las cuentas cuyo plazo venció. Se puede ejecutar las veces que sea: no repite cuentas ya anonimizadas.
export const purgarVencidos = async () => {
  // Los códigos de verificación (2FA y recuperar contraseña) solo valen 10 minutos: se borran los de más de un día
  await intentar('códigos vencidos', async () =>
    datos(await supabase.from('codigos_verificacion').delete().lt('expira_en', new Date(Date.now() - 24 * 3600 * 1000).toISOString())));

  const vencidos = datos(await supabase.from('usuarios').select('id')
    .not('eliminacion_programada_en', 'is', null)
    .lte('eliminacion_programada_en', new Date().toISOString())
    .is('anonimizado_en', null)
    .limit(50));
  for (const u of vencidos) {
    try {
      await anonimizarUsuario(u.id);
      console.log(`[PURGA] usuario ${u.id} anonimizado`);
    } catch (error) {
      console.error(`[PURGA] no se pudo anonimizar al usuario ${u.id}:`, error.message);
    }
  }
  return vencidos.length;
};
