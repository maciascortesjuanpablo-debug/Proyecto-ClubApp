
import { Router } from 'express';
import { obtenerNotificaciones, misNotificaciones, resumenNoLeidas, marcarNotificacionLeida, marcarTodasLeidas, eliminarNotificacion } from '../controllers/notificaciones.js';
import { verificarToken, propietarioOAdmin } from '../middlewares/middlewares.js';

const router = Router();

// Rutas fijas primero: van ANTES de las que llevan :id
router.get('/mias', verificarToken, misNotificaciones);
router.get('/mias/resumen', verificarToken, resumenNoLeidas);
router.put('/leer-todas', verificarToken, marcarTodasLeidas);

router.get('/usuario/:usuarioId', verificarToken, propietarioOAdmin('usuarioId'), obtenerNotificaciones);
router.put('/:id/leida', verificarToken, marcarNotificacionLeida);
router.delete('/:id', verificarToken, eliminarNotificacion); // solo si es del propio usuario

export default router;