import { Router } from 'express';
import { registrar, iniciarSesion } from '../controllers/auth.js';
import { autenticarConGoogle } from '../controllers/googleauth.js';
import { limiteAuth } from '../middlewares/limites.js';

const router = Router();

router.post('/registro', limiteAuth, registrar);
router.post('/login', limiteAuth, iniciarSesion);
router.post('/google', limiteAuth, autenticarConGoogle);

export default router;
