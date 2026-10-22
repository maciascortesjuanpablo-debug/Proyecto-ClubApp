import { Router } from 'express';
import { obtenerUsuarios, obtenerUsuarioPorId, actualizarUsuario, eliminarUsuario, cambiarPassword, elegirRol } from '../controllers/usuario.js';
import { verificarToken, verificarRol, propietarioOAdmin } from '../middlewares/middlewares.js';
import { limiteAuth } from '../middlewares/limites.js';
import { ROLES } from '../utils/helpers.js';

const router = Router();

router.get('/', verificarToken, verificarRol(ROLES.ADMIN), obtenerUsuarios);
router.post('/cambiar-password', verificarToken, limiteAuth, cambiarPassword); // la del usuario logueado
router.post('/elegir-rol', verificarToken, limiteAuth, elegirRol); // una sola vez (quien entró con Google)
router.get('/:id', verificarToken, propietarioOAdmin(), obtenerUsuarioPorId);
router.put('/:id', verificarToken, propietarioOAdmin(), actualizarUsuario);
router.delete('/:id', verificarToken, propietarioOAdmin(), eliminarUsuario);

export default router;