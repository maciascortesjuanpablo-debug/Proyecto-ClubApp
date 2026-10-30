import { Router } from 'express';
import {
  crearTorneo, obtenerTorneos, obtenerTorneoPorId, obtenerTorneosPorOrganizador,
  actualizarTorneo, eliminarTorneo, crearGrupo, obtenerGruposPorTorneo, torneoPropio, resumenTorneo,
} from '../controllers/torneos.js';
import { verificarToken, verificarRol, propietarioOAdmin } from '../middlewares/middlewares.js';
import { ROLES } from '../utils/helpers.js';

const router = Router();
const organizador = verificarRol(ROLES.ORGANIZADOR, ROLES.ADMIN);
// Solo el organizador del torneo (o Admin) puede modificarlo
const gestion = [verificarToken, organizador, torneoPropio];

router.post('/', verificarToken, organizador, crearTorneo);
router.get('/', obtenerTorneos);
router.get('/organizador/:organizadorId', verificarToken, propietarioOAdmin('organizadorId'), obtenerTorneosPorOrganizador); // los torneos de gestión son del propio organizador
router.get('/:id/resumen', resumenTorneo);
router.get('/:id', obtenerTorneoPorId);
router.put('/:id', ...gestion, actualizarTorneo);
router.delete('/:id', ...gestion, eliminarTorneo);

router.post('/:id/grupos', ...gestion, crearGrupo);
router.get('/:id/grupos', obtenerGruposPorTorneo);

export default router;
