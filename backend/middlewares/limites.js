import rateLimit from 'express-rate-limit';

const crear = (limit, minutos = 15) =>
  rateLimit({
    windowMs: minutos * 60 * 1000,
    limit,
    standardHeaders: true,
    legacyHeaders: false,
    message: { mensaje: 'Demasiados intentos, espera unos minutos e inténtalo de nuevo' },
  });

export const limiteGeneral = crear(300);
export const limiteAuth = crear(20);
export const limiteCodigos = crear(10);
export const limiteScout = crear(40);
