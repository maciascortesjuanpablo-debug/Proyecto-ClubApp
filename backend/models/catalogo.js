import { supabase } from '../config/supabase.js';
import { datos } from '../utils/helpers.js';

// Consultas genéricas de las tablas de catálogo
const listar = async (tabla, orden) => datos(await supabase.from(tabla).select('*').order(orden, { ascending: true }));
const buscar = async (tabla, id) => datos(await supabase.from(tabla).select('*').eq('id', id).maybeSingle());

export const catalogoModel = {
  listarRoles: () => listar('roles', 'id'),
  buscarRolPorId: (id) => buscar('roles', id),
  listarDeportes: () => listar('deportes', 'nombre'),
  buscarDeportePorId: (id) => buscar('deportes', id),
  listarFormatos: () => listar('formatos', 'nombre'),
  buscarFormatoPorId: (id) => buscar('formatos', id),
};
