import { Router } from 'express';
import {
  crearSede, obtenerSedes, crearEvento, obtenerEventosPorTorneo, obtenerEventoPorId,
  actualizarEvento, eliminarEvento, asignarArbitro, obtenerArbitrosPorEvento, eventoGestionable,
} from '../controllers/calendario.js';
import { verificarToken, verificarRol } from '../middlewares/middlewares.js';
import { ROLES } from '../utils/helpers.js';

const router = Router();
const organizador = verificarRol(ROLES.ORGANIZADOR, ROLES.ADMIN);
// Solo el organizador del torneo al que pertenece el evento (o Admin)
const gestion = [verificarToken, organizador, eventoGestionable];

router.post('/sedes', verificarToken, organizador, crearSede);
router.get('/sedes', obtenerSedes);

router.post('/eventos', verificarToken, organizador, crearEvento);
router.get('/eventos/torneo/:torneoId', obtenerEventosPorTorneo);
router.get('/eventos/:id', obtenerEventoPorId);
router.put('/eventos/:id', ...gestion, actualizarEvento);
router.delete('/eventos/:id', ...gestion, eliminarEvento);

router.post('/eventos/:id/arbitros', ...gestion, asignarArbitro);
router.get('/eventos/:id/arbitros', obtenerArbitrosPorEvento);

export default router;
