import express from 'express';
import cors from 'cors';
import helmet from 'helmet';
import dotenv from 'dotenv';
import { conectaDB } from './config/supabase.js';

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

dotenv.config();
conectaDB();

const app = express();
app.use(helmet());
app.use(cors());
app.use(express.json());

//Ruta login
app.use('/api/auth', authRoutes);
//Ruta usuarios
app.use('/api/usuarios', usuarioRoutes);
//Ruta recuperar contraseña
app.use('/api/recuperar-password', verificarCodigoRoutes);
//Ruta catalogo
app.use('/api/catalogo', catalogoRoutes);
//Ruta perfil jugador
app.use('/api/perfil-jugador', perfilJugadorRoutes);
//Ruta torneos
app.use('/api/torneos', torneosRoutes);
app.use('/api/equipos', equiposRoutes);
//Ruta equipos
app.use('/api/inscripciones', inscripcionesRoutes);
//Ruta calendario
app.use('/api/calendario', calendarioRoutes);
//Ruta estadisticas
app.use('/api/estadisticas', estadisticasRoutes);
//Rutas notificaciones
app.use('/api/notificaciones', notificacionesRoutes);
//Ruta favoritos
app.use('/api/favoritos', favoritosRoutes);


//Configuramos el puerto
const port = process.env.PORT || 3000;

//Poner a escuchar el servidor
app.listen(port, () => {
    console.log(`✅Servidor escuchando el puerto ${port}`);
    console.log(`http://localhost:${port}`);
});