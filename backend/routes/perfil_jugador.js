import { Router } from 'express';
import { crearPerfil, obtenerPerfilPorUsuario, actualizarPerfil, actualizarFotoPerfil } from '../controllers/perfil_jugador.js';
import { verificarToken, propietarioOAdmin } from '../middlewares/middlewares.js';
import { uploadFotoPerfil } from '../middlewares/upload.js';

const router = Router();
const propio = [verificarToken, propietarioOAdmin('usuarioId')]; // la autorización va ANTES de subir la imagen

router.post('/', verificarToken, crearPerfil);
router.get('/:usuarioId', verificarToken, obtenerPerfilPorUsuario);
router.put('/:usuarioId', ...propio, actualizarPerfil);
router.put('/:usuarioId/foto', ...propio, uploadFotoPerfil.single('foto'), actualizarFotoPerfil);

export default router;
