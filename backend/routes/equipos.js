import { Router } from 'express';
import {
  crearEquipo, obtenerEquipos, obtenerEquipoPorId, actualizarEquipo, eliminarEquipo,
  agregarJugadorEquipo, obtenerPlantilla, actualizarJugadorEquipo, eliminarJugadorEquipo,
  agregarStaffEquipo, obtenerStaffEquipo, eliminarStaffEquipo
} from '../controllers/equipos.js';
import { verificarToken } from '../middlewares/middlewares.js';

const router = Router();

router.post('/', verificarToken, crearEquipo);
router.get('/', obtenerEquipos);
router.get('/:id', obtenerEquipoPorId);
router.put('/:id', verificarToken, actualizarEquipo);
router.delete('/:id', verificarToken, eliminarEquipo);

router.post('/:id/jugadores', verificarToken, agregarJugadorEquipo);
router.get('/:id/jugadores', obtenerPlantilla);
router.put('/:id/jugadores/:usuarioId', verificarToken, actualizarJugadorEquipo);
router.delete('/:id/jugadores/:usuarioId', verificarToken, eliminarJugadorEquipo);

router.post('/:id/staff', verificarToken, agregarStaffEquipo);
router.get('/:id/staff', obtenerStaffEquipo);
router.delete('/:id/staff/:usuarioId', verificarToken, eliminarStaffEquipo);

export default router;