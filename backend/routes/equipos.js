import { Router } from 'express';
import {
  crearEquipo, obtenerEquipos, obtenerEquipoPorId, actualizarEquipo, eliminarEquipo,
  agregarJugadorEquipo, obtenerPlantilla, actualizarJugadorEquipo, eliminarJugadorEquipo,
  agregarStaffEquipo, obtenerStaffEquipo, eliminarStaffEquipo
} from '../controllers/equipos.js';
import { verificarToken, verificarRol } from '../middlewares/auth.js';

const router = Router();

router.post('/', verificarToken, verificarRol(3, 4, 6), crearEquipo);     // Entrenador, Organizador, Admin
router.get('/', obtenerEquipos);
router.get('/:id', obtenerEquipoPorId);
router.put('/:id', verificarToken, verificarRol(3, 4, 6), actualizarEquipo);
router.delete('/:id', verificarToken, verificarRol(3, 6), eliminarEquipo); // Entrenador (dueño), Admin

router.post('/:id/jugadores', verificarToken, verificarRol(3, 4, 6), agregarJugadorEquipo);
router.get('/:id/jugadores', obtenerPlantilla);
router.put('/:id/jugadores/:usuarioId', verificarToken, verificarRol(3, 4, 6), actualizarJugadorEquipo);
router.delete('/:id/jugadores/:usuarioId', verificarToken, verificarRol(3, 4, 6), eliminarJugadorEquipo);

router.post('/:id/staff', verificarToken, verificarRol(3, 4, 6), agregarStaffEquipo);
router.get('/:id/staff', obtenerStaffEquipo);
router.delete('/:id/staff/:usuarioId', verificarToken, verificarRol(3, 4, 6), eliminarStaffEquipo);

export default router;