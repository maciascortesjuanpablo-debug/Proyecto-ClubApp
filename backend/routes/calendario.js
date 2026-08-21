import { Router } from 'express';
import {
  crearSede, obtenerSedes, crearEvento, obtenerEventosPorTorneo, obtenerEventoPorId,
  actualizarEvento, eliminarEvento, asignarArbitro, obtenerArbitrosPorEvento
} from '../controllers/calendario.js';
import { verificarToken, verificarRol } from '../middlewares/middlewares.js';

const router = Router();

router.post('/sedes', verificarToken, verificarRol(4, 6), crearSede);
router.get('/sedes', obtenerSedes);

router.post('/eventos', verificarToken, verificarRol(4, 6), crearEvento);
router.get('/eventos/torneo/:torneoId', obtenerEventosPorTorneo);
router.get('/eventos/:id', obtenerEventoPorId);
router.put('/eventos/:id', verificarToken, verificarRol(4, 6), actualizarEvento);
router.delete('/eventos/:id', verificarToken, verificarRol(4, 6), eliminarEvento);

router.post('/eventos/:id/arbitros', verificarToken, verificarRol(4, 6), asignarArbitro);
router.get('/eventos/:id/arbitros', obtenerArbitrosPorEvento);

export default router;