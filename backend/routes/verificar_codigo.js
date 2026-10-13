import { Router } from 'express';
import { enviarCodigo, verificarCodigo, cambiarPassword } from '../controllers/verificar_codigo.js';
import { limiteCodigos } from '../middlewares/limites.js';

const router = Router();

router.post('/enviar-codigo', limiteCodigos, enviarCodigo);
router.post('/verificar-codigo', limiteCodigos, verificarCodigo);
router.post('/cambiar-password', limiteCodigos, cambiarPassword);

export default router;
