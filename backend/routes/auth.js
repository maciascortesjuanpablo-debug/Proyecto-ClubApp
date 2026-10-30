import { Router } from 'express';
import { registrar, iniciarSesion, verificarDosPasos, reenviarDosPasos } from '../controllers/auth.js';
import { autenticarConGoogle } from '../controllers/googleauth.js';
import { limiteAuth, limiteCodigos } from '../middlewares/limites.js';

const router = Router();

router.post('/registro', limiteAuth, registrar);
router.post('/login', limiteAuth, iniciarSesion);
router.post('/verificar-2fa', limiteCodigos, verificarDosPasos);
router.post('/reenviar-2fa', limiteCodigos, reenviarDosPasos);
router.post('/google', limiteAuth, autenticarConGoogle);

export default router;