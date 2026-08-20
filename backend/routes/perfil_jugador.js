import { Router } from 'express';
import { crearPerfil, obtenerPerfilPorUsuario, actualizarPerfil } from '../controllers/perfil_jugador.js';
import { verificarToken } from '../middlewares/middlewares.js';


const router = Router();

router.post('/', verificarToken, crearPerfil);
router.get('/:usuarioId', verificarToken, obtenerPerfilPorUsuario);
router.put('/:usuarioId', verificarToken, actualizarPerfil);

export default router;