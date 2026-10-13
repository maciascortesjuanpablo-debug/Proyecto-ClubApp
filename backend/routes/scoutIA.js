import { Router } from 'express';
import { chatConScout, obtenerHistorialScout, recomendarJugador, generarReporteEquipo } from '../controllers/scoutIA.js';
import { verificarToken, verificarRol } from '../middlewares/middlewares.js';
import { limiteScout } from '../middlewares/limites.js';
import { ROLES } from '../utils/helpers.js';

const router = Router();
const analistas = verificarRol(ROLES.ENTRENADOR, ROLES.ORGANIZADOR, ROLES.ADMIN);

router.use(verificarToken, limiteScout); // todo Scout AI requiere sesión y tiene límite de uso (cuesta dinero)

router.post('/chat', chatConScout);
router.get('/chat/historial/:conversacionId', obtenerHistorialScout);
router.post('/recomendaciones', analistas, recomendarJugador);
router.post('/reportes', analistas, generarReporteEquipo);

export default router;
