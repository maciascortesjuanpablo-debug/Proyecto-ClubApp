import { Router } from 'express';
import {
  crearPerfil,
  obtenerPerfilPorUsuario,
  actualizarPerfil,
  actualizarFotoPerfil,
} from '../controllers/perfil_jugador.js';
import { uploadFotoPerfil } from '../middlewares/upload.js';

const router = Router();

router.post('/', crearPerfil);
router.get('/:usuarioId', obtenerPerfilPorUsuario);
router.put('/:usuarioId', actualizarPerfil);
router.put('/:usuarioId/foto', uploadFotoPerfil.single('foto'), actualizarFotoPerfil);

export default router;