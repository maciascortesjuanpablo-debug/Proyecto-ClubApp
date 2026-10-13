import { Router } from 'express';
import { listarRoles, obtenerRol, listarDeportes, obtenerDeporte, listarFormatos, obtenerFormato } from '../controllers/catalogo.js';

const router = Router();

router.get('/roles', listarRoles);
router.get('/roles/:id', obtenerRol);
router.get('/deportes', listarDeportes);
router.get('/deportes/:id', obtenerDeporte);
router.get('/formatos', listarFormatos);
router.get('/formatos/:id', obtenerFormato);

export default router;
