import { supabase } from '../config/supabase.js';
import { usuarioModel } from '../models/usuario.js';
import { torneoModel } from '../models/torneos.js';
import { equipoModel } from '../models/equipos.js';
import { limpiarCambiosUsuario } from './usuario.js';
import { recalcularSeguro } from '../utils/posiciones.js';
import { ROLES, correoValido, datos, entero, esMismoUsuario, fallo, normalizarCorreo, pick, texto } from '../utils/helpers.js';

const TABLAS_ESTADO_INSCRIPCION = ['Pendiente', 'Aceptado', 'Rechazado'];

/* ---------- utilidades ---------- */
const auditar = (req, accion, detalle) => console.log(`[ADMIN] usuario ${req.usuario.id} · ${accion}`, detalle ?? '');

const contar = async (tabla, filtro) => {
  const consulta = supabase.from(tabla).select('id', { count: 'exact', head: true });
  const { count, error } = await (filtro ? filtro(consulta) : consulta);
  if (error) throw error;
  return count ?? 0;
};

const ids = (filas, campo = 'id') => filas.map((f) => f[campo]);
const agrupar = (filas, campo) => filas.reduce((acc, f) => ({ ...acc, [f[campo] ?? 'Sin dato']: (acc[f[campo] ?? 'Sin dato'] ?? 0) + 1 }), {});
const hayOtroAdmin = async (idExcluido) => (await contar('usuarios', (q) => q.eq('rol_id', ROLES.ADMIN).eq('activo', true).neq('id', idExcluido))) > 0;

const borrarEn = async (tabla, columna, valores) => {
  if (valores.length) datos(await supabase.from(tabla).delete().in(columna, valores));
};
// Tablas opcionales: si no existen o la columna no está, se sigue sin romper el borrado
const borrarOpcional = async (tabla, columna, valores) => {
  try {
    await borrarEn(tabla, columna, valores);
  } catch (error) {
    console.warn(`[ADMIN] limpieza opcional ${tabla}.${columna}: ${error.message}`);
  }
};

/* ---------- 1. RESUMEN ---------- */
export const resumen = async (req, res) => {
  try {
    const hace7 = new Date(Date.now() - 7 * 24 * 3600 * 1000).toISOString();
    const roles = Object.values(ROLES);
    const [total, activos, nuevos, torneos, equipos, pendientes, partidos, enVivo, finalizados, porRol, estados, marcadores] = await Promise.all([
      contar('usuarios'),
      contar('usuarios', (q) => q.eq('activo', true)),
      contar('usuarios', (q) => q.gte('creado_en', hace7)),
      contar('torneos'),
      contar('equipos'),
      contar('inscripciones_equipo', (q) => q.eq('estado', 'Pendiente')),
      contar('eventos_calendario', (q) => q.eq('tipo', 'Partido')),
      contar('eventos_calendario', (q) => q.eq('estado', 'En vivo')),
      contar('eventos_calendario', (q) => q.eq('tipo', 'Partido').eq('estado', 'Finalizado')),
      Promise.all(roles.map((rol) => contar('usuarios', (q) => q.eq('rol_id', rol)))),
      supabase.from('torneos').select('estado').limit(5000).then(datos),
      supabase.from('eventos_calendario').select('resultado_local, resultado_visitante').eq('tipo', 'Partido').eq('estado', 'Finalizado').limit(10000).then(datos),
    ]);

    res.json({
      usuarios: { total, activos, nuevos7d: nuevos, porRol: Object.fromEntries(roles.map((rol, i) => [rol, porRol[i]])) },
      torneos: { total: torneos, porEstado: agrupar(estados, 'estado') },
      equipos,
      inscripcionesPendientes: pendientes,
      partidos: { total: partidos, finalizados, enVivo },
      goles: marcadores.reduce((suma, m) => suma + (m.resultado_local ?? 0) + (m.resultado_visitante ?? 0), 0),
    });
  } catch (error) {
    fallo(res, error, 'Error al calcular el resumen');
  }
};

/* ---------- 2. USUARIOS ---------- */
const LIMITE_PAGINA = 20;

export const listarUsuarios = async (req, res) => {
  try {
    const buscar = texto(req.query.buscar, 60).replace(/[%,()*\\]/g, ' ').trim();
    const rol = entero(req.query.rol, 1, 6);
    const pagina = entero(req.query.pagina ?? 0, 0, 100000) ?? 0;

    let consulta = supabase.from('usuarios')
      .select('id, nombre, apellido, correo, numero_celular, fecha_nacimiento, ciudad, nivel_juego, rol_id, activo, correo_verificado, creado_en', { count: 'exact' })
      .order('creado_en', { ascending: false })
      .range(pagina * LIMITE_PAGINA, pagina * LIMITE_PAGINA + LIMITE_PAGINA - 1);
    if (buscar) consulta = consulta.or(`nombre.ilike.%${buscar}%,apellido.ilike.%${buscar}%,correo.ilike.%${buscar}%`);
    if (rol) consulta = consulta.eq('rol_id', rol);
    if (req.query.activo === 'true' || req.query.activo === 'false') consulta = consulta.eq('activo', req.query.activo === 'true');

    const { data, error, count } = await consulta;
    if (error) throw error;
    res.json({ usuarios: data, total: count ?? data.length, pagina, limite: LIMITE_PAGINA });
  } catch (error) {
    fallo(res, error, 'Error al listar los usuarios');
  }
};

export const actualizarUsuarioAdmin = async (req, res) => {
  try {
    const { id } = req.params;
    const objetivo = await usuarioModel.buscarPorId(id);
    if (!objetivo) return res.status(404).json({ mensaje: 'Usuario no encontrado' });

    const cambios = pick(req.body, ['nombre', 'apellido', 'numero_celular', 'fecha_nacimiento', 'ciudad', 'nivel_juego']);
    const errorDatos = limpiarCambiosUsuario(cambios);
    if (errorDatos) return res.status(400).json({ mensaje: errorDatos });

    if ('rol_id' in req.body) {
      const rol = Number(req.body.rol_id);
      if (!Object.values(ROLES).includes(rol)) return res.status(400).json({ mensaje: 'Rol no válido' });
      cambios.rol_id = rol;
    }
    for (const campo of ['activo', 'correo_verificado']) {
      if (!(campo in req.body)) continue;
      if (typeof req.body[campo] !== 'boolean') return res.status(400).json({ mensaje: `${campo} debe ser verdadero o falso` });
      cambios[campo] = req.body[campo];
    }
    if ('correo' in req.body) {
      const correo = normalizarCorreo(req.body.correo);
      if (!correoValido(correo)) return res.status(400).json({ mensaje: 'El correo no es válido' });
      const otro = await usuarioModel.buscarPorCorreo(correo);
      if (otro && String(otro.id) !== String(objetivo.id)) return res.status(409).json({ mensaje: 'Ese correo ya pertenece a otra cuenta' });
      cambios.correo = correo;
    }
    if (!Object.keys(cambios).length) return res.status(400).json({ mensaje: 'No hay campos válidos para actualizar' });

    const cambiaRol = 'rol_id' in cambios && cambios.rol_id !== objetivo.rol_id;
    if (esMismoUsuario(req, id) && (cambiaRol || cambios.activo === false)) {
      return res.status(400).json({ mensaje: 'No puedes cambiar tu propio rol ni desactivar tu cuenta' });
    }
    const dejaDeSerAdmin = objetivo.rol_id === ROLES.ADMIN && ((cambiaRol && cambios.rol_id !== ROLES.ADMIN) || cambios.activo === false);
    if (dejaDeSerAdmin && !(await hayOtroAdmin(objetivo.id))) {
      return res.status(409).json({ mensaje: 'Debe quedar al menos un administrador activo' });
    }

    auditar(req, 'usuario.actualizar', { id, cambios: Object.keys(cambios) });
    res.json({ mensaje: 'Usuario actualizado', usuario: await usuarioModel.actualizarUsuario(id, cambios) });
  } catch (error) {
    fallo(res, error, 'Error al actualizar el usuario');
  }
};

// Datos que cuelgan de un usuario y se borran con él (tabla, columna)
const DEPENDENCIAS_USUARIO = [
  ['favoritos', 'usuario_id'], ['notificaciones', 'usuario_id'], ['perfil_jugador', 'usuario_id'],
  ['equipo_jugadores', 'usuario_id'], ['equipo_staff', 'usuario_id'], ['estadisticas_jugador', 'usuario_id'],
  ['partido_arbitros', 'usuario_id'], ['codigos_verificacion', 'usuario_id'],
  ['invitaciones_equipo', 'usuario_id'], ['invitaciones_equipo', 'invitado_por'],
  ['scout_ai_recomendaciones', 'solicitado_por'], ['scout_ai_reportes', 'solicitado_por'],
];

export const eliminarUsuarioAdmin = async (req, res) => {
  try {
    const { id } = req.params;
    const permanente = req.query.permanente === 'true';
    const objetivo = await usuarioModel.buscarPorId(id);
    if (!objetivo) return res.status(404).json({ mensaje: 'Usuario no encontrado' });

    if (esMismoUsuario(req, id)) return res.status(400).json({ mensaje: 'No puedes eliminar tu propia cuenta' });
    if (objetivo.rol_id === ROLES.ADMIN && !(await hayOtroAdmin(objetivo.id))) {
      return res.status(409).json({ mensaje: 'Debe quedar al menos un administrador activo' });
    }

    // Por defecto solo se desactiva (reversible): los datos del usuario se conservan
    if (!permanente) {
      await usuarioModel.eliminar(objetivo.id);
      auditar(req, 'usuario.desactivar', { id });
      return res.json({ mensaje: 'Usuario desactivado' });
    }

    const organizados = await contar('torneos', (q) => q.eq('organizador_id', objetivo.id));
    if (organizados) {
      return res.status(409).json({ mensaje: `Organiza ${organizados} torneo(s): reasígnalos o elimínalos antes de borrar al usuario` });
    }

    for (const [tabla, columna] of DEPENDENCIAS_USUARIO) await borrarOpcional(tabla, columna, [objetivo.id]);
    // Conversaciones de Scout AI con sus mensajes
    try {
      const conversaciones = ids(datos(await supabase.from('scout_ai_conversaciones').select('id').eq('usuario_id', objetivo.id)));
      await borrarEn('scout_ai_mensajes', 'conversacion_id', conversaciones);
      await borrarEn('scout_ai_conversaciones', 'id', conversaciones);
    } catch (error) {
      console.warn(`[ADMIN] limpieza de Scout AI: ${error.message}`);
    }
    // Los equipos que creó se conservan, solo pierden al dueño
    await supabase.from('equipos').update({ creado_por: null }).eq('creado_por', objetivo.id);

    const { error } = await supabase.from('usuarios').delete().eq('id', objetivo.id);
    if (error) {
      if (error.code === '23503') return res.status(409).json({ mensaje: 'No se puede eliminar: todavía tiene datos asociados. Desactívalo en su lugar' });
      throw error;
    }
    auditar(req, 'usuario.eliminar', { id, correo: objetivo.correo });
    res.json({ mensaje: 'Usuario eliminado definitivamente' });
  } catch (error) {
    fallo(res, error, 'Error al eliminar el usuario');
  }
};

/* ---------- 3. TORNEOS ---------- */
export const listarTorneosAdmin = async (req, res) => {
  try {
    const [torneos, inscripciones, partidos] = await Promise.all([
      supabase.from('torneos')
        .select('id, nombre, estado, ciudad, max_equipos, jornada_actual, jornada_total, organizador_id, creado_en, deportes ( id, nombre ), formatos ( id, nombre ), usuarios ( id, nombre, apellido )')
        .order('creado_en', { ascending: false }).limit(1000).then(datos),
      supabase.from('inscripciones_equipo').select('torneo_id, estado').limit(10000).then(datos),
      supabase.from('eventos_calendario').select('torneo_id, estado, resultado_local, resultado_visitante').eq('tipo', 'Partido').limit(10000).then(datos),
    ]);

    res.json({
      torneos: torneos.map((t) => {
        const insc = inscripciones.filter((i) => String(i.torneo_id) === String(t.id));
        const jugados = partidos.filter((p) => String(p.torneo_id) === String(t.id) && p.estado === 'Finalizado');
        return {
          ...t,
          equipos: insc.filter((i) => i.estado === 'Aceptado').length,
          pendientes: insc.filter((i) => i.estado === 'Pendiente').length,
          partidos: partidos.filter((p) => String(p.torneo_id) === String(t.id)).length,
          finalizados: jugados.length,
          goles: jugados.reduce((s, p) => s + (p.resultado_local ?? 0) + (p.resultado_visitante ?? 0), 0),
        };
      }),
    });
  } catch (error) {
    fallo(res, error, 'Error al listar los torneos');
  }
};

export const actualizarTorneoAdmin = async (req, res) => {
  try {
    const cambios = pick(req.body, ['nombre', 'deporte_id', 'formato_id', 'max_equipos', 'ciudad', 'jornada_total', 'jornada_actual', 'estado']);
    if ('nombre' in cambios && !(cambios.nombre = texto(cambios.nombre, 120))) return res.status(400).json({ mensaje: 'El nombre no puede estar vacío' });
    if ('estado' in cambios && !(cambios.estado = texto(cambios.estado, 30))) return res.status(400).json({ mensaje: 'El estado no puede estar vacío' });
    if ('ciudad' in cambios) cambios.ciudad = texto(cambios.ciudad) || null;
    for (const [campo, min, max] of [['max_equipos', 2, 256], ['jornada_total', 0, 500], ['jornada_actual', 0, 500]]) {
      if (campo in cambios && (cambios[campo] = entero(cambios[campo], min, max)) === null) {
        return res.status(400).json({ mensaje: `${campo} debe ser un número entre ${min} y ${max}` });
      }
    }
    if ('organizador_id' in req.body) {
      const nuevo = await usuarioModel.buscarPorId(req.body.organizador_id);
      if (!nuevo?.activo || ![ROLES.ORGANIZADOR, ROLES.ADMIN].includes(nuevo.rol_id)) {
        return res.status(400).json({ mensaje: 'El organizador debe ser un usuario activo con rol Organizador o Administrador' });
      }
      cambios.organizador_id = nuevo.id;
    }
    if (!Object.keys(cambios).length) return res.status(400).json({ mensaje: 'No hay campos válidos para actualizar' });
    if (!(await torneoModel.buscarPorId(req.params.id))) return res.status(404).json({ mensaje: 'Torneo no encontrado' });

    auditar(req, 'torneo.actualizar', { id: req.params.id, cambios: Object.keys(cambios) });
    res.json({ mensaje: 'Torneo actualizado', torneo: await torneoModel.actualizar(req.params.id, cambios) });
  } catch (error) {
    fallo(res, error, 'Error al actualizar el torneo');
  }
};

// Borra el torneo con todo lo que depende de él: partidos (con árbitros y estadísticas), inscripciones y tabla de posiciones
export const eliminarTorneoAdmin = async (req, res) => {
  try {
    const torneo = await torneoModel.buscarPorId(req.params.id);
    if (!torneo) return res.status(404).json({ mensaje: 'Torneo no encontrado' });

    const [inscripciones, eventos] = await Promise.all([
      supabase.from('inscripciones_equipo').select('id').eq('torneo_id', torneo.id).then(datos).then(ids),
      supabase.from('eventos_calendario').select('id').eq('torneo_id', torneo.id).then(datos).then(ids),
    ]);

    await borrarEn('estadisticas_jugador', 'evento_id', eventos);
    await borrarEn('partido_arbitros', 'evento_id', eventos);
    await borrarEn('eventos_calendario', 'id', eventos);
    await borrarEn('tabla_posiciones', 'inscripcion_id', inscripciones);
    await borrarEn('inscripciones_equipo', 'id', inscripciones);
    await borrarOpcional('grupos_torneo', 'torneo_id', [torneo.id]);
    await borrarOpcional('favoritos', 'torneo_id', [torneo.id]);
    await borrarOpcional('scout_ai_recomendaciones', 'torneo_id', [torneo.id]);
    datos(await supabase.from('torneos').delete().eq('id', torneo.id));

    auditar(req, 'torneo.eliminar', { id: torneo.id, nombre: torneo.nombre, partidos: eventos.length, inscripciones: inscripciones.length });
    res.json({ mensaje: 'Torneo eliminado con todos sus datos' });
  } catch (error) {
    fallo(res, error, 'Error al eliminar el torneo');
  }
};

/* ---------- 4. EQUIPOS ---------- */
export const listarEquiposAdmin = async (req, res) => {
  try {
    const [equipos, jugadores, inscripciones] = await Promise.all([
      supabase.from('equipos').select('*').order('creado_en', { ascending: false }).limit(1000).then(datos),
      supabase.from('equipo_jugadores').select('equipo_id').limit(20000).then(datos),
      supabase.from('inscripciones_equipo').select('equipo_id').eq('estado', 'Aceptado').limit(10000).then(datos),
    ]);
    const jugadoresPor = agrupar(jugadores, 'equipo_id');
    const torneosPor = agrupar(inscripciones, 'equipo_id');
    res.json({ equipos: equipos.map((e) => ({ ...e, jugadores: jugadoresPor[e.id] ?? 0, torneos: torneosPor[e.id] ?? 0 })) });
  } catch (error) {
    fallo(res, error, 'Error al listar los equipos');
  }
};

// Borra el equipo con su plantilla, staff, invitaciones, inscripciones y los partidos en que jugaba
export const eliminarEquipoAdmin = async (req, res) => {
  try {
    const equipo = await equipoModel.buscarPorId(req.params.id);
    if (!equipo) return res.status(404).json({ mensaje: 'Equipo no encontrado' });

    const [inscripciones, eventos] = await Promise.all([
      supabase.from('inscripciones_equipo').select('id, torneo_id').eq('equipo_id', equipo.id).then(datos),
      supabase.from('eventos_calendario').select('id, torneo_id').or(`equipo_local_id.eq.${equipo.id},equipo_visitante_id.eq.${equipo.id}`).then(datos),
    ]);
    const torneosAfectados = [...new Set([...ids(inscripciones, 'torneo_id'), ...ids(eventos, 'torneo_id')].filter(Boolean))];

    await borrarEn('estadisticas_jugador', 'evento_id', ids(eventos));
    await borrarEn('partido_arbitros', 'evento_id', ids(eventos));
    await borrarEn('eventos_calendario', 'id', ids(eventos));
    await borrarEn('estadisticas_jugador', 'equipo_id', [equipo.id]);
    await borrarEn('tabla_posiciones', 'inscripcion_id', ids(inscripciones));
    await borrarEn('inscripciones_equipo', 'id', ids(inscripciones));
    await borrarEn('equipo_jugadores', 'equipo_id', [equipo.id]);
    await borrarEn('equipo_staff', 'equipo_id', [equipo.id]);
    await borrarOpcional('invitaciones_equipo', 'equipo_id', [equipo.id]);
    await borrarOpcional('favoritos', 'equipo_id', [equipo.id]);
    datos(await supabase.from('equipos').delete().eq('id', equipo.id));

    // Al desaparecer sus partidos cambian las tablas de posiciones de los demás
    await Promise.all(torneosAfectados.map(recalcularSeguro));

    auditar(req, 'equipo.eliminar', { id: equipo.id, nombre: equipo.nombre });
    res.json({ mensaje: 'Equipo eliminado con todos sus datos' });
  } catch (error) {
    fallo(res, error, 'Error al eliminar el equipo');
  }
};

/* ---------- 5. INSCRIPCIONES ---------- */
export const listarInscripcionesAdmin = async (req, res) => {
  try {
    const estado = TABLAS_ESTADO_INSCRIPCION.includes(req.query.estado) ? req.query.estado : 'Pendiente';
    const [filas, torneos] = await Promise.all([
      supabase.from('inscripciones_equipo')
        .select('id, estado, fecha_inscripcion, torneo_id, equipos ( id, nombre, logo_url )')
        .eq('estado', estado).order('fecha_inscripcion', { ascending: false }).limit(200).then(datos),
      supabase.from('torneos').select('id, nombre').limit(1000).then(datos),
    ]);
    const nombres = Object.fromEntries(torneos.map((t) => [t.id, t.nombre]));
    res.json({ inscripciones: filas.map((i) => ({ ...i, torneo: nombres[i.torneo_id] ?? 'Torneo eliminado' })) });
  } catch (error) {
    fallo(res, error, 'Error al listar las inscripciones');
  }
};