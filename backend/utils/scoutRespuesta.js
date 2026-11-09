// Control de calidad de las respuestas de Scout AI: que no repita lo que ya dijo, que no invente turnos de conversación
// y que los rechazos y avisos no sean siempre el mismo texto. Son funciones puras, fáciles de probar.

// Mensajes cuando la pregunta no es de ClubApp: varían para no repetir siempre lo mismo
export const RECHAZOS = [
  'Eso se sale de lo que puedo hacer: solo te ayudo con ClubApp (equipos, torneos, partidos, calendario, jugadores y cómo usar la app). ¿Qué necesitas de la aplicación?',
  'Solo puedo ayudarte con temas de ClubApp. Si quieres, te explico cómo crear un equipo, armar una alineación, inscribirte a un torneo o revisar tus partidos.',
  'Ese tema no es de ClubApp, así que no puedo ayudarte con eso. Pregúntame por tus equipos, torneos, el calendario, las posiciones o cualquier función de la app.',
  'Mi trabajo es ayudarte con ClubApp y no con otros temas. ¿Te ayudo con algo de la app, como un torneo, un equipo o una notificación?',
  'Para eso no te sirvo: solo respondo sobre ClubApp. Dime qué quieres hacer en la app y te guío paso a paso.',
];

// Cuando la pregunta ya se respondió y no hay nada nuevo que decir
export const SIN_NOVEDAD = [
  'Eso ya te lo expliqué un poco más arriba. ¿Quieres que lo detalle de otra forma o tienes otra duda sobre ClubApp?',
  'Esa parte ya quedó explicada antes. ¿Qué punto no te quedó claro, o avanzamos con otra consulta?',
  'Ya te di esa información en mi respuesta anterior. Dime qué paso te cuesta y te lo explico distinto.',
];

const elegirDistinto = (opciones, previas) => opciones.find((o) => !previas.includes(o)) ?? opciones[previas.length % opciones.length];
export const rechazoVariado = (previas) => elegirDistinto(RECHAZOS, previas);
export const sinNovedadVariado = (previas) => elegirDistinto(SIN_NOVEDAD, previas);
export const esRechazo = (t) => RECHAZOS.includes(t) || SIN_NOVEDAD.includes(t);

const sinAcentos = (s) => String(s ?? '').normalize('NFD').replace(/[\u0300-\u036f]/g, '');
export const normalizar = (s) => sinAcentos(s).toLowerCase().replace(/[^a-z0-9\s]/g, ' ').replace(/\s+/g, ' ').trim();
const palabras = (s) => new Set(normalizar(s).split(' ').filter((p) => p.length > 3));

// Parecido entre dos textos (0 a 1): palabras en común sobre palabras totales
export const similitud = (a, b) => {
  const A = palabras(a);
  const B = palabras(b);
  if (!A.size || !B.size) return 0;
  let comunes = 0;
  A.forEach((p) => B.has(p) && comunes++);
  return comunes / (A.size + B.size - comunes);
};

// Quita etiquetas de rol ("Scout AI:", "Usuario:") y los turnos de conversación que el modelo a veces inventa
export const cortarDialogoInventado = (texto) => {
  let r = String(texto ?? '').replace(/^\s*(scout ?ai|asistente|assistant)\s*:\s*/i, '');
  const turno = /(^|\n)\s*(usuario|user|humano|persona|asistente|assistant|scout ?ai)\s*:/i.exec(r);
  if (turno && turno.index > 0) r = r.slice(0, turno.index);
  return r.replace(/\[id:[^\]]*\]/gi, '').trim();
};

// Si la respuesta empieza copiando una respuesta anterior (mensajes "uno encima de otro"), se quita esa parte.
// Tampoco deja líneas largas repetidas dentro de la misma respuesta.
export const quitarRepetido = (respuesta, previas) => {
  const previasNorm = previas.map(normalizar).filter((p) => p.length >= 30);
  let r = String(respuesta ?? '').trim();

  // 1) Empieza con una respuesta anterior completa
  for (const previa of previas) {
    const p = String(previa).trim();
    if (p.length >= 30 && r.startsWith(p)) r = r.slice(p.length).trim();
  }

  // 2) Líneas del inicio que ya se dijeron antes
  const lineas = r.split('\n');
  while (lineas.length) {
    const n = normalizar(lineas[0]);
    if (n.length >= 30 && previasNorm.some((p) => p.includes(n))) lineas.shift();
    else if (!n) lineas.shift();
    else break;
  }

  // 3) Líneas largas repetidas dentro de la misma respuesta
  const vistas = new Set();
  const unicas = lineas.filter((l) => {
    const n = normalizar(l);
    if (n.length < 30) return true;
    if (vistas.has(n)) return false;
    vistas.add(n);
    return true;
  });
  return unicas.join('\n').trim();
};

// ¿Es casi igual a alguna respuesta anterior?
export const esRepetida = (respuesta, previas) => {
  if (palabras(respuesta).size < 8) return false; // las respuestas muy cortas ("Listo.") pueden coincidir sin ser un problema
  return previas.some((p) => similitud(respuesta, p) >= 0.82);
};

// Limpieza completa de lo que devuelve el modelo
export const limpiarRespuesta = (cruda, previas) => quitarRepetido(cortarDialogoInventado(cruda), previas);