//Variables de entorno
import dotenv from 'dotenv/config';
import { createClient } from '@supabase/supabase-js';


//Creacion de la conexion a supabase

const supabaseUrl = process.env.SUPABASE_URL;
const supabaseKey = process.env.SUPABASE_KEY;

//variables de conexion

if (!supabaseUrl || !supabaseKey) {
    console.error("❌Error: Las variables de entorno SUPABASE_URL y SUPABASE_KEY son requeridas.");
    process.exit(1);
}

//Conexion a supabase
export const supabase = createClient(supabaseUrl, supabaseKey);
export const conectaDB = () => {
    console.log("✅Conexión a Supabase establecida correctamente.");
};
