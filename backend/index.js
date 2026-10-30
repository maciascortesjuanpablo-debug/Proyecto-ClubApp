import 'dotenv/config'; // siempre primero: el resto de módulos lee process.env al cargarse
import express from 'express';
import cors from 'cors';
import helmet from 'helmet';
import { conectaDB } from './config/supabase.js';
import { limiteGeneral } from './middlewares/limites.js';

import authRoutes from './routes/auth.js';
import usuarioRoutes from './routes/usuario.js';
import verificarCodigoRoutes from './routes/verificar_codigo.js';
import catalogoRoutes from './routes/catalogo.js';
import perfilJugadorRoutes from './routes/perfil_jugador.js';
import torneosRoutes from './routes/torneos.js';
import equiposRoutes from './routes/equipos.js';
import inscripcionesRoutes from './routes/inscripciones.js';
import calendarioRoutes from './routes/calendario.js';
import estadisticasRoutes from './routes/estadisticas.js';
import notificacionesRoutes from './routes/notificaciones.js';
import favoritosRoutes from './routes/favoritos.js';
import scoutIARoutes from './routes/scoutIA.js';
import homeRoutes from './routes/home.js';
import adminRoutes from './routes/admin.js'; 
import panelRoutes from './routes/panel.js';

conectaDB();

const app = express();
// Detrás de un proxy (Render, Railway...) define TRUST_PROXY=1 para que el límite de peticiones use la IP real
if (process.env.TRUST_PROXY) app.set('trust proxy', Number(process.env.TRUST_PROXY));
app.use(helmet());
app.use(cors());

// Rutas de salud para el monitor: van ANTES del límite de peticiones
// para que los chequeos frecuentes nunca reciban un 429
app.get('/', (req, res) => res.status(200).json({ estado: 'ok' }));
app.get('/health', (req, res) => res.status(200).send('OK'));

app.use(express.json({ limit: '100kb' }));
app.use(limiteGeneral);

const rutas = {
  auth: authRoutes,
  usuarios: usuarioRoutes,
  'recuperar-password': verificarCodigoRoutes,
  catalogo: catalogoRoutes,
  'perfil-jugador': perfilJugadorRoutes,
  torneos: torneosRoutes,
  equipos: equiposRoutes,
  inscripciones: inscripcionesRoutes,
  calendario: calendarioRoutes,
  estadisticas: estadisticasRoutes,
  notificaciones: notificacionesRoutes,
  favoritos: favoritosRoutes,
  scout: scoutIARoutes,
  home: homeRoutes,
  admin: adminRoutes,
  panel: panelRoutes,
};
for (const [ruta, router] of Object.entries(rutas)) app.use(`/api/${ruta}`, router);

app.use((req, res) => res.status(404).json({ mensaje: 'Ruta no encontrada' }));

// Manejador global: nunca devuelve detalles internos
// eslint-disable-next-line no-unused-vars
app.use((err, req, res, next) => {
  if (err.type === 'entity.parse.failed') return res.status(400).json({ mensaje: 'JSON inválido' });
  if (err.type === 'entity.too.large') return res.status(413).json({ mensaje: 'La petición es demasiado grande' });
  if (err.name === 'MulterError' || err.message?.startsWith('Solo se permiten')) return res.status(400).json({ mensaje: err.message });
  console.error(err);
  res.status(500).json({ mensaje: 'Error interno del servidor' });
});

const port = process.env.PORT || 3000;
app.listen(port, () => console.log(`✅ Servidor escuchando en http://localhost:${port}`));
