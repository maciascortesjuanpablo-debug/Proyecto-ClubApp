import { Router } from 'express';
import { registrar, iniciarSesion } from '../controllers/auth.js';
import { autenticarConGoogle } from "../controllers/googleauth.js";

const router = Router();

router.post('/registro', registrar);
router.post('/login', iniciarSesion);
// Endpoint: POST /api/auth/google
router.post("/google", autenticarConGoogle);

export default router;