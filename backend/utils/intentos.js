// Límite de intentos fallidos por clave (en memoria). El contador NO se reinicia al pedir un código nuevo:
// solo expira al pasar la ventana, así reenviar códigos no da intentos infinitos.
export const crearLimiteIntentos = (max = 5, ventanaMs = 15 * 60 * 1000) => {
  const mapa = new Map();
  const vigente = (clave) => {
    const e = mapa.get(clave);
    if (e && e.hasta < Date.now()) { mapa.delete(clave); return null; }
    return e ?? null;
  };
  return {
    bloqueado: (clave) => (vigente(clave)?.n ?? 0) >= max,
    fallo: (clave) => {
      const e = vigente(clave) ?? { n: 0, hasta: Date.now() + ventanaMs };
      e.n += 1;
      mapa.set(clave, e);
    },
    limpiar: (clave) => mapa.delete(clave),
  };
};
