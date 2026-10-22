import { Router } from 'express';
import {
  resumen, listarUsuarios, actualizarUsuarioAdmin, eliminarUsuarioAdmin,
  listarTorneosAdmin, actualizarTorneoAdmin, eliminarTorneoAdmin,
  listarEquiposAdmin, eliminarEquipoAdmin, listarInscripcionesAdmin,
} from '../controllers/admin.js';
import { verificarToken, verificarRol, adminVigente } from '../middlewares/middlewares.js';
import { ROLES } from '../utils/helpers.js';

const router = Router();

// Todo el panel es solo para administradores (token válido + rol confirmado en la base de datos)
router.use(verificarToken, verificarRol(ROLES.ADMIN), adminVigente);

router.get('/resumen', resumen);

router.get('/usuarios', listarUsuarios);
router.put('/usuarios/:id', actualizarUsuarioAdmin);
router.delete('/usuarios/:id', eliminarUsuarioAdmin); // ?permanente=true para borrarlo de verdad

router.get('/torneos', listarTorneosAdmin);
router.put('/torneos/:id', actualizarTorneoAdmin);
router.delete('/torneos/:id', eliminarTorneoAdmin);

// Editar un equipo y quitar jugadores ya lo permiten PUT /equipos/:id y DELETE /equipos/:id/jugadores/:usuarioId (admin pasa siempre)
router.get('/equipos', listarEquiposAdmin);
router.delete('/equipos/:id', eliminarEquipoAdmin);

// Aprobar o rechazar usa PUT /inscripciones/:id/estado
router.get('/inscripciones', listarInscripcionesAdmin);

export default router;