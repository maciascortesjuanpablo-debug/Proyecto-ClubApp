import express from 'express';
import cors from 'cors';
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

dotenv.config();
conectaDB();

const app = express();
app.use(cors());
app.use(express.json());

app.use('/api/auth', authRoutes);
app.use('/api/usuarios', usuarioRoutes);
app.use('/api/recuperar-password', verificarCodigoRoutes);
app.use('/api/catalogo', catalogoRoutes);
app.use('/api/perfil-jugador', perfilJugadorRoutes);
app.use('/api/torneos', torneosRoutes);
app.use('/api/equipos', equiposRoutes);
app.use('/api/inscripciones', inscripcionesRoutes);


//Configuramos el puerto
const port = process.env.PORT || 3000;

//Poner a escuchar el servidor
app.listen(port, () => {
    console.log(`✅Servidor escuchando el puerto ${port}`);
    console.log(`http://localhost:${port}`);
});