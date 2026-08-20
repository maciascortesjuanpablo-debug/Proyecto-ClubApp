import { Router } from 'express';
import {
  inscribirEquipo, obtenerInscripcionesPorTorneo, actualizarEstadoInscripcion,
  obtenerTablaPosiciones,
  crearInvitacion, obtenerInvitacionesPorUsuario, responderInvitacion
} from '../controllers/inscripciones.js';
import { verificarToken } from '../middlewares/middlewares.js';

const router = Router();

router.post('/', verificarToken, inscribirEquipo);
router.get('/torneo/:torneoId', obtenerInscripcionesPorTorneo);
router.put('/:id/estado', verificarToken, actualizarEstadoInscripcion);

router.get('/tabla-posiciones/:torneoId', obtenerTablaPosiciones);

router.post('/invitaciones', verificarToken, crearInvitacion);
router.get('/invitaciones/usuario/:usuarioId', verificarToken, obtenerInvitacionesPorUsuario);
router.put('/invitaciones/:id/responder', verificarToken, responderInvitacion);

export default router;