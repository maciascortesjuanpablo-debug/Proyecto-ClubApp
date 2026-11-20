import { usuarioModel } from '../models/usuario.js';

// Debe coincidir con LegalTexts.version de la app (ClubApp/lib/core/legal_texts.dart).
// Al subirla, todos los usuarios deberán aceptar de nuevo en su próximo ingreso.
export const VERSION_POLITICA = '1.1';

// Edad en años a partir de AAAA-MM-DD; null si la fecha no es válida, es futura o es absurda
export const edadDe = (fecha) => {
  if (!/^\d{4}-\d{2}-\d{2}$/.test(String(fecha ?? ''))) return null;
  const [y, m, d] = String(fecha).split('-').map(Number);
  const nac = new Date(Date.UTC(y, m - 1, d));
  if (Number.isNaN(nac.getTime()) || nac.getUTCMonth() !== m - 1 || nac.getUTCDate() !== d) return null;
  const hoy = new Date();
  let edad = hoy.getUTCFullYear() - y;
  if (hoy.getUTCMonth() < m - 1 || (hoy.getUTCMonth() === m - 1 && hoy.getUTCDate() < d)) edad -= 1;
  return edad < 0 || edad > 120 ? null : edad;
};

// Qué le falta a esta cuenta para tener la autorización vigente. Si algo falla no bloquea el ingreso.
export const estadoConsentimiento = async (id) => {
  try {
    const c = await usuarioModel.consentimiento(id);
    const edad = edadDe(c?.fecha_nacimiento ? String(c.fecha_nacimiento).slice(0, 10) : null);
    return {
      requiere_aceptacion: c?.version_politica !== VERSION_POLITICA,
      falta_fecha_nacimiento: edad === null,
      es_menor: edad !== null && edad < 18,
    };
  } catch (error) {
    console.error('Consultando consentimiento (¿falta ejecutar backend/sql/003?):', error.message);
    return { requiere_aceptacion: false, falta_fecha_nacimiento: false, es_menor: false };
  }
};
