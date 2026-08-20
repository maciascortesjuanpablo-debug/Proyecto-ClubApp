import { inscripcionModel } from '../models/inscripciones.js';


// ---- INSCRIPCIONES ----

export const inscribirEquipo = async (req, res) => {
  try {
    const { torneo_id, equipo_id } = req.body;

    if (!torneo_id || !equipo_id) {
      return res.status(400).json({ mensaje: 'torneo_id y equipo_id son obligatorios' });
    }

    const inscripcion = await inscripcionModel.inscribirEquipo({ torneo_id, equipo_id });
    res.status(201).json({ mensaje: 'Equipo inscrito, pendiente de aprobación', inscripcion });

  } catch (error) {
    console.error(error);
    res.status(500).json({ mensaje: 'Error al inscribir el equipo', error: error.message });
  }
};

export const obtenerInscripcionesPorTorneo = async (req, res) => {
  try {
    const { torneoId } = req.params;
    const inscripciones = await inscripcionModel.listarPorTorneo(torneoId);
    res.json(inscripciones);
  } catch (error) {
    console.error(error);
    res.status(500).json({ mensaje: 'Error al obtener las inscripciones', error: error.message });
  }
};

export const actualizarEstadoInscripcion = async (req, res) => {
  try {
    const { id } = req.params;
    const { estado } = req.body; // 'Aceptado' o 'Rechazado'

    if (!['Pendiente', 'Aceptado', 'Rechazado'].includes(estado)) {
      return res.status(400).json({ mensaje: 'Estado no válido' });
    }

    const inscripcion = await inscripcionModel.actualizarEstado(id, { estado });

    // Si se aceptó, se crea automáticamente su fila en la tabla de posiciones
    if (estado === 'Aceptado') {
      await inscripcionModel.crearTablaPosiciones(id);
    }

    res.json({ mensaje: 'Estado actualizado', inscripcion });

  } catch (error) {
    console.error(error);
    res.status(500).json({ mensaje: 'Error al actualizar el estado', error: error.message });
  }
};

// ---- TABLA DE POSICIONES ----

export const obtenerTablaPosiciones = async (req, res) => {
  try {
    const { torneoId } = req.params;
    const tabla = await inscripcionModel.obtenerTablaPorTorneo(torneoId);
    res.json(tabla);
  } catch (error) {
    console.error(error);
    res.status(500).json({ mensaje: 'Error al obtener la tabla de posiciones', error: error.message });
  }
};

// ---- INVITACIONES ----

export const crearInvitacion = async (req, res) => {
  try {
    const { equipo_id, usuario_id, posicion_propuesta } = req.body;

    if (!equipo_id || !usuario_id) {
      return res.status(400).json({ mensaje: 'equipo_id y usuario_id son obligatorios' });
    }

    const invitacion = await inscripcionModel.crearInvitacion({
      equipo_id,
      usuario_id,
      posicion_propuesta,
      invitado_por: req.usuario.id
    });

    res.status(201).json({ mensaje: 'Invitación enviada', invitacion });

  } catch (error) {
    console.error(error);
    res.status(500).json({ mensaje: 'Error al crear la invitación', error: error.message });
  }
};

export const obtenerInvitacionesPorUsuario = async (req, res) => {
  try {
    const { usuarioId } = req.params;
    const invitaciones = await inscripcionModel.listarInvitacionesPorUsuario(usuarioId);
    res.json(invitaciones);
  } catch (error) {
    console.error(error);
    res.status(500).json({ mensaje: 'Error al obtener las invitaciones', error: error.message });
  }
};

export const responderInvitacion = async (req, res) => {
  try {
    const { id } = req.params;
    const { respuesta } = req.body; // 'Aceptada' o 'Rechazada'

    if (!['Aceptada', 'Rechazada'].includes(respuesta)) {
      return res.status(400).json({ mensaje: 'Respuesta no válida' });
    }

    const invitacion = await inscripcionModel.buscarInvitacionPorId(id);
    if (!invitacion) {
      return res.status(404).json({ mensaje: 'Invitación no encontrada' });
    }

    await inscripcionModel.actualizarInvitacion(id, { estado: respuesta });

    // Si aceptó, se agrega de una vez como jugador del equipo
    if (respuesta === 'Aceptada') {
      await equipoModel.agregarJugador({
        equipo_id: invitacion.equipo_id,
        usuario_id: invitacion.usuario_id,
        posicion: invitacion.posicion_propuesta || 'Sin asignar'
      });
    }

    res.json({ mensaje: `Invitación ${respuesta.toLowerCase()}` });

  } catch (error) {
    console.error(error);
    res.status(500).json({ mensaje: 'Error al responder la invitación', error: error.message });
  }
};