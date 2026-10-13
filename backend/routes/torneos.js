import { Router } from 'express';
import {
  crearTorneo, obtenerTorneos, obtenerTorneoPorId, obtenerTorneosPorOrganizador,
  actualizarTorneo, eliminarTorneo, crearGrupo, obtenerGruposPorTorneo, torneoPropio,
} from '../controllers/torneos.js';
import { verificarToken, verificarRol } from '../middlewares/middlewares.js';
import { ROLES } from '../utils/helpers.js';

const router = Router();
const organizador = verificarRol(ROLES.ORGANIZADOR, ROLES.ADMIN);
// Solo el organizador del torneo (o Admin) puede modificarlo
const gestion = [verificarToken, organizador, torneoPropio];

router.post('/', verificarToken, organizador, crearTorneo);
router.get('/', obtenerTorneos);
router.get('/:id', obtenerTorneoPorId);
router.get('/organizador/:organizadorId', verificarToken, obtenerTorneosPorOrganizador);
router.put('/:id', ...gestion, actualizarTorneo);
router.delete('/:id', ...gestion, eliminarTorneo);

router.post('/:id/grupos', ...gestion, crearGrupo);
router.get('/:id/grupos', obtenerGruposPorTorneo);

export default router;
