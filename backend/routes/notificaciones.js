import { Router } from 'express';
import { obtenerNotificaciones, marcarNotificacionLeida } from '../controllers/notificaciones.js';
import { verificarToken, propietarioOAdmin } from '../middlewares/middlewares.js';

const router = Router();

router.get('/usuario/:usuarioId', verificarToken, propietarioOAdmin('usuarioId'), obtenerNotificaciones);
router.put('/:id/leida', verificarToken, marcarNotificacionLeida);

export default router;
