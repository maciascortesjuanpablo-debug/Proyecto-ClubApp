import { Router } from 'express';
import {
  crearTorneo, obtenerTorneos, obtenerTorneoPorId, obtenerTorneosPorOrganizador,
  actualizarTorneo, eliminarTorneo, crearGrupo, obtenerGruposPorTorneo
} from '../controllers/torneos.js';
import { verificarToken } from '../middleware/verificarToken.js';

const router = Router();

router.post('/', verificarToken, crearTorneo);
router.get('/', obtenerTorneos); // público, se puede ver sin login
router.get('/:id', obtenerTorneoPorId);
router.get('/organizador/:organizadorId', verificarToken, obtenerTorneosPorOrganizador);
router.put('/:id', verificarToken, actualizarTorneo);
router.delete('/:id', verificarToken, eliminarTorneo);

router.post('/:id/grupos', verificarToken, crearGrupo);
router.get('/:id/grupos', obtenerGruposPorTorneo);

export default router;