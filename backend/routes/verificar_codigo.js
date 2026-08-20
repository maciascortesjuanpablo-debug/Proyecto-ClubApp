import { Router } from 'express';
import { enviarCodigo, verificarCodigo, cambiarPassword } from '../controllers/verificar_codigo.js';

const router = Router();

router.post('/enviar-codigo', enviarCodigo);
router.post('/verificar-codigo', verificarCodigo);
router.post('/cambiar-password', cambiarPassword);

export default router;