import { Router } from 'express';
import { panelJugador, panelEntrenador, panelOrganizador, panelArbitro } from '../controllers/panel.js';
import { verificarToken, verificarRol } from '../middlewares/middlewares.js';
import { ROLES } from '../utils/helpers.js';

const router = Router();

// Cada panel es exclusivo de su rol: un token de otro rol recibe 403. (El admin tiene su propio panel en /admin.)
router.use(verificarToken);
router.get('/jugador', verificarRol(ROLES.JUGADOR), panelJugador);
router.get('/entrenador', verificarRol(ROLES.ENTRENADOR), panelEntrenador);
router.get('/organizador', verificarRol(ROLES.ORGANIZADOR), panelOrganizador);
router.get('/arbitro', verificarRol(ROLES.ARBITRO), panelArbitro);

export default router;
