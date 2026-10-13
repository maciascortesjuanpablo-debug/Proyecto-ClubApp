import { Router } from 'express';
import {
  crearEstadistica, obtenerEstadisticasPorEvento, obtenerEstadisticasPorJugador,
  actualizarEstadistica, eliminarEstadistica,
} from '../controllers/estadisticas.js';
import { verificarToken, verificarRol } from '../middlewares/middlewares.js';
import { ROLES } from '../utils/helpers.js';

const { ENTRENADOR, ORGANIZADOR, ARBITRO, ADMIN } = ROLES;
const router = Router();
const registran = verificarRol(ENTRENADOR, ORGANIZADOR, ARBITRO, ADMIN); // el controlador valida además el partido concreto

router.post('/', verificarToken, registran, crearEstadistica);
router.get('/evento/:eventoId', obtenerEstadisticasPorEvento);
router.get('/jugador/:usuarioId', obtenerEstadisticasPorJugador);
router.put('/:id', verificarToken, registran, actualizarEstadistica);
router.delete('/:id', verificarToken, verificarRol(ADMIN), eliminarEstadistica); // solo Admin borra

export default router;
