import { Router } from 'express';
import { registrar, iniciarSesion } from '../controllers/auth.js';

const router = Router();

router.post('/registro', registrar);
router.post('/login', iniciarSesion);

export default router;