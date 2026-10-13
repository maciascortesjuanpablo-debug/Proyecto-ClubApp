import { Router } from 'express';
import {
  crearEquipo, obtenerEquipos, obtenerEquipoPorId, actualizarEquipo, eliminarEquipo, equipoPropio,
  agregarJugadorEquipo, obtenerPlantilla, actualizarJugadorEquipo, eliminarJugadorEquipo,
  agregarStaffEquipo, obtenerStaffEquipo, eliminarStaffEquipo,
} from '../controllers/equipos.js';
import { verificarToken, verificarRol } from '../middlewares/middlewares.js';
import { ROLES } from '../utils/helpers.js';

const { ENTRENADOR, ORGANIZADOR, ADMIN } = ROLES;
const router = Router();
// Solo el dueño del equipo (o Admin) puede modificarlo
const gestion = [verificarToken, verificarRol(ENTRENADOR, ORGANIZADOR, ADMIN), equipoPropio];

router.post('/', verificarToken, verificarRol(ENTRENADOR, ORGANIZADOR, ADMIN), crearEquipo);
router.get('/', obtenerEquipos);
router.get('/:id', obtenerEquipoPorId);
router.put('/:id', ...gestion, actualizarEquipo);
router.delete('/:id', ...gestion, eliminarEquipo);

router.post('/:id/jugadores', ...gestion, agregarJugadorEquipo);
router.get('/:id/jugadores', obtenerPlantilla);
router.put('/:id/jugadores/:usuarioId', ...gestion, actualizarJugadorEquipo);
router.delete('/:id/jugadores/:usuarioId', ...gestion, eliminarJugadorEquipo);

router.post('/:id/staff', ...gestion, agregarStaffEquipo);
router.get('/:id/staff', obtenerStaffEquipo);
router.delete('/:id/staff/:usuarioId', ...gestion, eliminarStaffEquipo);

export default router;
