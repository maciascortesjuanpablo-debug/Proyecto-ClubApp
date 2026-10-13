import { Router } from 'express';
import { obtenerHomePublico, obtenerHomeUsuario } from '../controllers/home.js';
import { verificarToken } from '../middlewares/middlewares.js';

const router = Router();

router.get('/publico', obtenerHomePublico);
router.get('/', verificarToken, obtenerHomeUsuario);

export default router;