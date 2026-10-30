import { Router } from 'express';
import {
  inscribirEquipo, obtenerInscripcionesPorTorneo, actualizarEstadoInscripcion, obtenerTablaPosiciones,
  crearInvitacion, obtenerInvitacionesPorUsuario, responderInvitacion,
} from '../controllers/inscripciones.js';
import { verificarToken, verificarRol, propietarioOAdmin } from '../middlewares/middlewares.js';
import { ROLES } from '../utils/helpers.js';

const { ENTRENADOR, ORGANIZADOR, JUGADOR, ADMIN } = ROLES;
const router = Router();

router.post('/', verificarToken, verificarRol(ENTRENADOR, ADMIN), inscribirEquipo); // inscribir un equipo es cosa del entrenador
router.get('/torneo/:torneoId', obtenerInscripcionesPorTorneo);
router.put('/:id/estado', verificarToken, verificarRol(ORGANIZADOR, ADMIN), actualizarEstadoInscripcion); // organizador del torneo o Admin

router.get('/tabla-posiciones/:torneoId', obtenerTablaPosiciones);

router.post('/invitaciones', verificarToken, verificarRol(ENTRENADOR, ADMIN), crearInvitacion);
router.get('/invitaciones/usuario/:usuarioId', verificarToken, propietarioOAdmin('usuarioId'), obtenerInvitacionesPorUsuario);
router.put('/invitaciones/:id/responder', verificarToken, verificarRol(JUGADOR), responderInvitacion); // solo un jugador, y solo su destinatario

export default router;
