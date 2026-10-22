import { Router } from 'express';
import {
  crearSede, obtenerSedes, crearEvento, listarEventos, misEventos, obtenerEventosPorTorneo, obtenerEventoPorId,
  actualizarEvento, registrarResultado, eliminarEvento, arbitrosDisponibles, asignarArbitro, quitarArbitro,
  obtenerArbitrosPorEvento, eventoGestionable,
} from '../controllers/calendario.js';
import { verificarToken, verificarRol } from '../middlewares/middlewares.js';
import { ROLES } from '../utils/helpers.js';

const router = Router();
const organizador = verificarRol(ROLES.ORGANIZADOR, ROLES.ADMIN);
// Solo el organizador del torneo al que pertenece el evento (o Admin)
const gestion = [verificarToken, organizador, eventoGestionable];

router.post('/sedes', verificarToken, organizador, crearSede);
router.get('/sedes', obtenerSedes);

// Calendario general (?desde=AAAA-MM-DD&hasta=AAAA-MM-DD) y "mis partidos"
router.get('/eventos', listarEventos);
router.get('/mis-eventos', verificarToken, misEventos);

router.post('/eventos', verificarToken, organizador, crearEvento);
router.get('/eventos/torneo/:torneoId', obtenerEventosPorTorneo);
router.get('/eventos/:id', obtenerEventoPorId);
router.put('/eventos/:id', ...gestion, actualizarEvento);
// Estado y marcador: organizador, admin o el árbitro asignado a ese partido (el controlador lo verifica)
router.put('/eventos/:id/resultado', verificarToken, verificarRol(ROLES.ORGANIZADOR, ROLES.ARBITRO, ROLES.ADMIN), registrarResultado);
router.delete('/eventos/:id', ...gestion, eliminarEvento);

router.get('/arbitros', verificarToken, organizador, arbitrosDisponibles);
router.post('/eventos/:id/arbitros', ...gestion, asignarArbitro);
router.get('/eventos/:id/arbitros', obtenerArbitrosPorEvento);

router.delete('/eventos/:id/arbitros/:arbitroId', ...gestion, quitarArbitro);

export default router;