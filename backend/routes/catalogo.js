import express from 'express';
import { 
    listarRoles, 
    obtenerRol, 
    listarDeportes, 
    obtenerDeporte, 
    listarFormatos, 
    obtenerFormato 
} from '../controllers/catalogo.js';

const router = express.Router();

// Rutas de roles
router.get('/roles', listarRoles);
router.get('/roles/:id', obtenerRol);

// Rutas de deportes
router.get('/deportes', listarDeportes);
router.get('/deportes/:id', obtenerDeporte);

// Rutas de formatos
router.get('/formatos', listarFormatos);
router.get('/formatos/:id', obtenerFormato);

export default router;