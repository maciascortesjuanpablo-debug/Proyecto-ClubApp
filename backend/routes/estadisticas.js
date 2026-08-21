import { Router } from 'express';
import {
  crearEstadistica, obtenerEstadisticasPorEvento, obtenerEstadisticasPorJugador,
  actualizarEstadistica, eliminarEstadistica
} from '../controllers/estadisticas.js';
import { verificarToken, verificarRol } from '../middlewares/middlewares.js';

const router = Router();

router.post('/', verificarToken, verificarRol(3, 4, 5, 6), crearEstadistica); // Entrenador, Organizador, Arbitro, Admin
router.get('/evento/:eventoId', obtenerEstadisticasPorEvento);
router.get('/jugador/:usuarioId', obtenerEstadisticasPorJugador);
router.put('/:id', verificarToken, verificarRol(3, 4, 5, 6), actualizarEstadistica);
router.delete('/:id', verificarToken, verificarRol(6), eliminarEstadistica); // Solo Admin borra

export default router;