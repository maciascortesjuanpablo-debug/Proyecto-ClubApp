import { Router } from 'express';
import { agregarFavorito, obtenerFavoritos, eliminarFavorito } from '../controllers/favoritos.js';
import { verificarToken, propietarioOAdmin } from '../middlewares/middlewares.js';

const router = Router();

router.post('/', verificarToken, agregarFavorito);
router.get('/usuario/:usuarioId', verificarToken, propietarioOAdmin('usuarioId'), obtenerFavoritos);
router.delete('/:id', verificarToken, eliminarFavorito);

export default router;
