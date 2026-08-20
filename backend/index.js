import express from 'express';
import dotenv from 'dotenv';
import cors from 'cors';
import { conectaDB, supabase } from './config/supabase.js';
import usuarioRoutes from './routes/usuario.js';
import catalogoRoutes from './routes/catalogo.js';
import perfilJugadorRoutes from './routes/perfil_jugador.js';
import inscripcionesRoutes from './routes/inscripciones.js';

// Cargar variables de entorno
dotenv.config();
conectaDB();


//Creamos la aplicacio de express
const app = express();

app.use(cors());
//Leer el json 
app.use(express.json());

//Rutas de usuario
app.use('/usuarios', usuarioRoutes);

//rutas de catalogo
app.use('/catalogo', catalogoRoutes);

//rutas de perfil de jugador
app.use('/perfil-jugador', perfilJugadorRoutes);

//rutas de inscripciones
app.use('/inscripciones', inscripcionesRoutes);


//Configuramos el puerto
const port = process.env.PORT || 3000;

//Poner a escuchar el servidor
app.listen(port, () => {
    console.log(`✅Servidor escuchando el puerto ${port}`);
    console.log(`http://localhost:${port}`);
});