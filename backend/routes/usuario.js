import { Router } from 'express';
import { obtenerUsuarios, obtenerUsuarioPorId, actualizarUsuario, eliminarUsuario } from '../controllers/usuario.js';
import { verificarToken, verificarRol, propietarioOAdmin } from '../middlewares/middlewares.js';
import { ROLES } from '../utils/helpers.js';

const router = Router();

router.get('/', verificarToken, verificarRol(ROLES.ADMIN), obtenerUsuarios);
router.get('/:id', verificarToken, propietarioOAdmin(), obtenerUsuarioPorId);
router.put('/:id', verificarToken, propietarioOAdmin(), actualizarUsuario);
router.delete('/:id', verificarToken, propietarioOAdmin(), eliminarUsuario);

export default router;
