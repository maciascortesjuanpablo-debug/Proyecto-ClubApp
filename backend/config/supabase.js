import 'dotenv/config';
import { createClient } from '@supabase/supabase-js';

const supabaseUrl = process.env.SUPABASE_URL;
// Si defines SUPABASE_SERVICE_ROLE_KEY (solo en el servidor) se usa esa; si no, SUPABASE_KEY
const supabaseKey = process.env.SUPABASE_SERVICE_ROLE_KEY ?? process.env.SUPABASE_KEY;

if (!supabaseUrl || !supabaseKey) {
  console.error('❌ Faltan variables de entorno: SUPABASE_URL y SUPABASE_KEY son requeridas.');
  process.exit(1);
}

export const supabase = createClient(supabaseUrl, supabaseKey, { auth: { persistSession: false } });

// Prueba real de conexión
export const conectaDB = async () => {
  const { error } = await supabase.from('roles').select('id').limit(1);
  console.log(error ? `❌ No se pudo consultar Supabase: ${error.message}` : '✅ Conexión a Supabase verificada.');
};
