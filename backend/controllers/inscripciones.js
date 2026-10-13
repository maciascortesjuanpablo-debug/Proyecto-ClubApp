import { inscripcionModel } from '../models/inscripciones.js';
import { equipoModel } from '../models/equipos.js';
import { torneoModel } from '../models/torneos.js';
import { notificar } from '../models/notificaciones.js';
import { fallo } from '../utils/helpers.js';
import { esDuenoEquipo, esOrganizadorTorneo } from '../utils/permisos.js';

const TORNEO_CERRADO = ['Finalizado', 'Cancelado'];

// ---- INSCRIPCIONES ----

export const inscribirEquipo = async (req, res) => {
  try {
    const { torneo_id, equipo_id } = req.body;
    if (!torneo_id || !equipo_id) return res.status(400).json({ mensaje: 'torneo_id y equipo_id son obligatorios' });

    const [torneo, equipo] = await Promise.all([torneoModel.buscarPorId(torneo_id), equipoModel.buscarPorId(equipo_id)]);
    if (!torneo || !equipo) return res.status(404).json({ mensaje: 'Torneo o equipo no encontrado' });
    if (!esDuenoEquipo(req, equipo)) return res.status(403).json({ mensaje: 'Solo el dueño del equipo puede inscribirlo' });
    if (TORNEO_CERRADO.includes(torneo.estado)) return res.status(409).json({ mensaje: 'El torneo ya no admite inscripciones' });
    if (await inscripcionModel.buscarPorTorneoYEquipo(torneo_id, equipo_id)) {
      return res.status(409).json({ mensaje: 'El equipo ya está inscrito en este torneo' });
    }

    const inscripcion = await inscripcionModel.inscribirEquipo({ torneo_id, equipo_id });
    if (torneo.organizador_id) await notificar(torneo.organizador_id, `El equipo "${equipo.nombre}" solicitó inscribirse en "${torneo.nombre}"`);
    res.status(201).json({ mensaje: 'Equipo inscrito, pendiente de aprobación', inscripcion });
  } catch (error) {
    fallo(res, error, 'Error al inscribir el equipo');
  }
};

export const obtenerInscripcionesPorTorneo = async (req, res) => {
  try {
    res.json(await inscripcionModel.listarPorTorneo(req.params.torneoId));
  } catch (error) {
    fallo(res, error, 'Error al obtener las inscripciones');
  }
};

export const actualizarEstadoInscripcion = async (req, res) => {
  try {
    const { estado } = req.body; // 'Aceptado' o 'Rechazado'
    if (!['Pendiente', 'Aceptado', 'Rechazado'].includes(estado)) return res.status(400).json({ mensaje: 'Estado no válido' });

    const actual = await inscripcionModel.buscarPorId(req.params.id);
    if (!actual) return res.status(404).json({ mensaje: 'Inscripción no encontrada' });

    const torneo = await torneoModel.buscarPorId(actual.torneo_id);
    if (!torneo || !esOrganizadorTorneo(req, torneo)) return res.status(403).json({ mensaje: 'No organizas este torneo' });

    if (estado === 'Aceptado' && actual.estado !== 'Aceptado' && (await inscripcionModel.contarAceptadas(torneo.id)) >= torneo.max_equipos) {
      return res.status(409).json({ mensaje: 'El torneo ya alcanzó el máximo de equipos' });
    }

    const inscripcion = await inscripcionModel.actualizarEstado(req.params.id, { estado });

    // Aceptado: tiene fila en la tabla de posiciones (sin duplicarla). Otro estado: se retira
    if (estado === 'Aceptado') await inscripcionModel.asegurarFilaTabla(inscripcion.id);
    else await inscripcionModel.eliminarFilaTabla(inscripcion.id);

    if (estado !== actual.estado && estado !== 'Pendiente') {
      const equipo = await equipoModel.buscarPorId(actual.equipo_id);
      if (equipo?.creado_por) await notificar(equipo.creado_por, `Tu equipo "${equipo.nombre}" fue ${estado.toLowerCase()} en "${torneo.nombre}"`);
    }

    res.json({ mensaje: 'Estado actualizado', inscripcion });
  } catch (error) {
    fallo(res, error, 'Error al actualizar el estado');
  }
};

// ---- TABLA DE POSICIONES ----

export const obtenerTablaPosiciones = async (req, res) => {
  try {
    const filas = await inscripcionModel.obtenerTablaPorTorneo(req.params.torneoId);
    // Orden: puntos, diferencia de gol, goles a favor
    const tabla = filas
      .sort((a, b) => b.puntos - a.puntos || (b.goles_favor - b.goles_contra) - (a.goles_favor - a.goles_contra) || b.goles_favor - a.goles_favor)
      .map((f, i) => ({ ...f, posicion: i + 1 }));
    res.json(tabla);
  } catch (error) {
    fallo(res, error, 'Error al obtener la tabla de posiciones');
  }
};

// ---- INVITACIONES ----

export const crearInvitacion = async (req, res) => {
  try {
    const { equipo_id, usuario_id, posicion_propuesta } = req.body;
    if (!equipo_id || !usuario_id) return res.status(400).json({ mensaje: 'equipo_id y usuario_id son obligatorios' });

    const equipo = await equipoModel.buscarPorId(equipo_id);
    if (!equipo) return res.status(404).json({ mensaje: 'Equipo no encontrado' });
    if (!esDuenoEquipo(req, equipo)) return res.status(403).json({ mensaje: 'Solo el dueño del equipo puede invitar' });
    if (await equipoModel.buscarJugador(equipo_id, usuario_id)) return res.status(409).json({ mensaje: 'Ese jugador ya está en el equipo' });
    if (await inscripcionModel.buscarInvitacionPendiente(equipo_id, usuario_id)) {
      return res.status(409).json({ mensaje: 'Ya hay una invitación pendiente para ese jugador' });
    }

    const invitacion = await inscripcionModel.crearInvitacion({ equipo_id, usuario_id, posicion_propuesta, invitado_por: req.usuario.id });
    await notificar(usuario_id, `El equipo "${equipo.nombre}" te invitó a unirte`);
    res.status(201).json({ mensaje: 'Invitación enviada', invitacion });
  } catch (error) {
    fallo(res, error, 'Error al crear la invitación');
  }
};

export const obtenerInvitacionesPorUsuario = async (req, res) => {
  try {
    res.json(await inscripcionModel.listarInvitacionesPorUsuario(req.params.usuarioId));
  } catch (error) {
    fallo(res, error, 'Error al obtener las invitaciones');
  }
};

export const responderInvitacion = async (req, res) => {
  try {
    const { respuesta } = req.body; // 'Aceptada' o 'Rechazada'
    if (!['Aceptada', 'Rechazada'].includes(respuesta)) return res.status(400).json({ mensaje: 'Respuesta no válida' });

    const invitacion = await inscripcionModel.buscarInvitacionPorId(req.params.id);
    // Una invitación ajena se trata como inexistente
    if (!invitacion || String(invitacion.usuario_id) !== String(req.usuario.id)) {
      return res.status(404).json({ mensaje: 'Invitación no encontrada' });
    }
    if (invitacion.estado !== 'Pendiente') return res.status(409).json({ mensaje: 'Esta invitación ya fue respondida' });

    // Primero se agrega al jugador y solo después se marca la invitación, para no quedar a medias
    if (respuesta === 'Aceptada' && !(await equipoModel.buscarJugador(invitacion.equipo_id, invitacion.usuario_id))) {
      await equipoModel.agregarJugador({
        equipo_id: invitacion.equipo_id,
        usuario_id: invitacion.usuario_id,
        posicion: invitacion.posicion_propuesta || 'Sin asignar',
      });
    }
    await inscripcionModel.actualizarInvitacion(req.params.id, { estado: respuesta });

    if (invitacion.invitado_por) {
      const equipo = await equipoModel.buscarPorId(invitacion.equipo_id);
      await notificar(invitacion.invitado_por, `Tu invitación a "${equipo?.nombre ?? 'tu equipo'}" fue ${respuesta.toLowerCase()}`);
    }
    res.json({ mensaje: `Invitación ${respuesta.toLowerCase()}` });
  } catch (error) {
    fallo(res, error, 'Error al responder la invitación');
  }
};
