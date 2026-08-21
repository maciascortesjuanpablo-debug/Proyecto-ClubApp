import { Router } from 'express';
import {
  crearTorneo, obtenerTorneos, obtenerTorneoPorId, obtenerTorneosPorOrganizador,
  actualizarTorneo, eliminarTorneo, crearGrupo, obtenerGruposPorTorneo
} from '../controllers/torneos.js';
import { verificarToken, verificarRol } from '../middlewares/auth.js';

const router = Router();

router.post('/', verificarToken, verificarRol(4, 6), crearTorneo);        // Organizador, Admin
router.get('/', obtenerTorneos);
router.get('/:id', obtenerTorneoPorId);
router.get('/organizador/:organizadorId', verificarToken, obtenerTorneosPorOrganizador);
router.put('/:id', verificarToken, verificarRol(4, 6), actualizarTorneo);
router.delete('/:id', verificarToken, verificarRol(4, 6), eliminarTorneo);

router.post('/:id/grupos', verificarToken, verificarRol(4, 6), crearGrupo);
router.get('/:id/grupos', obtenerGruposPorTorneo);

export default router;