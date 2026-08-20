import { Router } from 'express';
import {
  obtenerUsuarios,
  obtenerUsuarioPorId,
  actualizarUsuario,
  eliminarUsuario
} from '../controllers/usuario.js';
import { verificarToken } from '../middlewares/middlewares.js';


const router = Router();

router.get('/', verificarToken, obtenerUsuarios);
router.get('/:id', verificarToken, obtenerUsuarioPorId);
router.put('/:id', verificarToken, actualizarUsuario);
router.delete('/:id', verificarToken, eliminarUsuario);

export default router;