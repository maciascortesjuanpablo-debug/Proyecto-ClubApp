import { Router } from 'express';
import {
  inscribirEquipo, obtenerInscripcionesPorTorneo, actualizarEstadoInscripcion,
  obtenerTablaPosiciones,
  crearInvitacion, obtenerInvitacionesPorUsuario, responderInvitacion
} from '../controllers/inscripciones.js';
import { verificarToken, verificarRol } from '../middlewares/middlewares.js';

const router = Router();

router.post('/', verificarToken, verificarRol(3, 4, 6), inscribirEquipo);  // Entrenador, Organizador, Admin
router.get('/torneo/:torneoId', obtenerInscripcionesPorTorneo);
router.put('/:id/estado', verificarToken, verificarRol(4, 6), actualizarEstadoInscripcion); // Solo Organizador acepta/rechaza

router.get('/tabla-posiciones/:torneoId', obtenerTablaPosiciones);

router.post('/invitaciones', verificarToken, verificarRol(3, 4, 6), crearInvitacion);
router.get('/invitaciones/usuario/:usuarioId', verificarToken, obtenerInvitacionesPorUsuario);
router.put('/invitaciones/:id/responder', verificarToken, responderInvitacion); // cualquier usuario responde SU propia invitación

export default router;