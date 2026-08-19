import express from 'express';
import dotenv from 'dotenv';
import { conectaDB,supabase } from './config/supabase.js';
import CatalogoRoutes from './routes/catalogo.js';

// Cargar variables de entorno
dotenv.config();
conectaDB();

//Creamos la aplicacio de express
const app = express();

//Leer el json 
app.use(express.json());

//rutas de catalogo
app.use('/catalogo', CatalogoRoutes);


//Configuramos el puerto
const port = process.env.PORT || 3000;

//Poner a escuchar el servidor
app.listen(port, () => {
    console.log(`✅Servidor escuchando el puerto ${port}`);
    console.log(`http://localhost:${port}`);
});