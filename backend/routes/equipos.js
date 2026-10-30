import { Router } from 'express';
import {
  crearEquipo, obtenerEquipos, obtenerEquipoPorId, actualizarEquipo, eliminarEquipo, equipoPropio,
  agregarJugadorEquipo, obtenerPlantilla, actualizarJugadorEquipo, eliminarJugadorEquipo,
  agregarStaffEquipo, obtenerStaffEquipo, eliminarStaffEquipo, misEquipos, partidosDeEquipo, buscarJugadores,
} from '../controllers/equipos.js';
import { verificarToken, verificarRol } from '../middlewares/middlewares.js';
import { ROLES } from '../utils/helpers.js';

const { ENTRENADOR, JUGADOR, ADMIN } = ROLES;
const router = Router();
// Los equipos los gestiona el entrenador (solo el dueño del equipo) o el Admin; el organizador administra torneos, no equipos
const gestion = [verificarToken, verificarRol(ENTRENADOR, ADMIN), equipoPropio];

router.post('/', verificarToken, verificarRol(ENTRENADOR, ADMIN), crearEquipo);
router.get('/', obtenerEquipos);
// Rutas fijas: van ANTES de /:id
router.get('/mios', verificarToken, verificarRol(ENTRENADOR, JUGADOR), misEquipos);
router.get('/buscar-jugadores', verificarToken, verificarRol(ENTRENADOR, ADMIN), buscarJugadores);
router.get('/:id/partidos', partidosDeEquipo);
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
