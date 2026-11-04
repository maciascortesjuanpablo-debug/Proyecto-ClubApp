// Generación automática de partidos (fixture) y reparto en fechas y horarios.
// Son funciones puras (sin base de datos) para poder probarlas con facilidad.

const MS_DIA = 86_400_000;
const partesFecha = (fecha) => fecha.split('-').map(Number);

export const sumarDias = (fecha, n) => {
  const [y, m, d] = partesFecha(fecha);
  return new Date(Date.UTC(y, m - 1, d) + n * MS_DIA).toISOString().slice(0, 10);
};
// 0 = domingo … 6 = sábado
export const diaSemana = (fecha) => {
  const [y, m, d] = partesFecha(fecha);
  return new Date(Date.UTC(y, m - 1, d)).getUTCDay();
};

// Mezcla reproducible: la misma semilla da siempre el mismo orden (así la vista previa y la creación coinciden)
const generador = (semilla) => {
  let a = (semilla >>> 0) || 1;
  return () => {
    a = (a + 0x6d2b79f5) >>> 0;
    let t = Math.imul(a ^ (a >>> 15), 1 | a);
    t = (t + Math.imul(t ^ (t >>> 7), 61 | t)) ^ t;
    return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
  };
};
export const mezclar = (lista, semilla) => {
  const azar = generador(semilla);
  const copia = [...lista];
  for (let i = copia.length - 1; i > 0; i--) {
    const j = Math.floor(azar() * (i + 1));
    [copia[i], copia[j]] = [copia[j], copia[i]];
  }
  return copia;
};

// Todos contra todos (método del círculo): cada equipo juega una vez por ronda. Devuelve [[[local, visitante], …], …]
export const todosContraTodos = (equipos) => {
  const lista = [...equipos];
  if (lista.length % 2) lista.push(null); // si son impares, uno descansa cada ronda
  const n = lista.length;
  const rondas = [];
  for (let r = 0; r < n - 1; r++) {
    const ronda = [];
    for (let i = 0; i < n / 2; i++) {
      let a = lista[i];
      let b = lista[n - 1 - i];
      if (a === null || b === null) continue;
      if ((r + i) % 2 === 1) [a, b] = [b, a]; // reparte las localías
      ronda.push([a, b]);
    }
    rondas.push(ronda);
    lista.splice(1, 0, lista.pop()); // el primero queda fijo y los demás rotan
  }
  return rondas;
};

const conVuelta = (rondas) => [...rondas, ...rondas.map((r) => r.map(([a, b]) => [b, a]))];

// Reparto en grupos "en serpiente" (1,2,3,3,2,1…) para equilibrar
export const repartirEnGrupos = (equipos, numGrupos) => {
  const grupos = Array.from({ length: numGrupos }, () => []);
  equipos.forEach((e, i) => {
    const pos = Math.floor(i / numGrupos) % 2 === 0 ? i % numGrupos : numGrupos - 1 - (i % numGrupos);
    grupos[pos].push(e);
  });
  return grupos;
};

const LETRAS = 'ABCDEFGH';
const nombreRonda = (equiposEnRonda) => ({ 2: 'Final', 4: 'Semifinal', 8: 'Cuartos de final', 16: 'Octavos de final', 32: 'Dieciseisavos de final' }[equiposEnRonda] ?? `Ronda de ${equiposEnRonda}`);

// Primera ronda de eliminación directa. Si no son potencia de 2, los mejores sembrados (primeros de la lista) pasan directo.
export const primeraRondaEliminacion = (equipos) => {
  let tam = 2;
  while (tam < equipos.length) tam *= 2;
  const directos = tam - equipos.length;
  const juegan = equipos.slice(directos);
  const partidos = [];
  for (let i = 0; i < juegan.length / 2; i++) partidos.push([juegan[i], juegan[juegan.length - 1 - i]]);
  return { partidos, directos: equipos.slice(0, directos), fase: nombreRonda(tam) };
};

// Devuelve { rondas: [{ jornada, partidos: [{ local, visitante, fase }] }], grupos?, directos? }
export const generarRondas = ({ modo, equipos, numGrupos = 2, idaVueltaGrupos = false }) => {
  if (modo === 'todos' || modo === 'ida_vuelta') {
    const base = todosContraTodos(equipos);
    const mitad = base.length;
    const rondas = (modo === 'ida_vuelta' ? conVuelta(base) : base).map((ronda, i) => ({
      jornada: i + 1,
      partidos: ronda.map(([local, visitante]) => ({ local, visitante, fase: modo === 'ida_vuelta' ? (i < mitad ? 'Ida' : 'Vuelta') : null })),
    }));
    return { rondas };
  }
  if (modo === 'grupos') {
    const grupos = repartirEnGrupos(equipos, numGrupos);
    const porGrupo = grupos.map((g) => (idaVueltaGrupos ? conVuelta(todosContraTodos(g)) : todosContraTodos(g)));
    const total = Math.max(...porGrupo.map((r) => r.length));
    const rondas = [];
    for (let r = 0; r < total; r++) {
      const partidos = [];
      porGrupo.forEach((rondasGrupo, g) => (rondasGrupo[r] ?? []).forEach(([local, visitante]) => partidos.push({ local, visitante, fase: `Grupo ${LETRAS[g]}` })));
      rondas.push({ jornada: r + 1, partidos });
    }
    return { rondas, grupos: grupos.map((equiposGrupo, g) => ({ nombre: `Grupo ${LETRAS[g]}`, equipos: equiposGrupo })) };
  }
  // eliminacion
  const { partidos, directos, fase } = primeraRondaEliminacion(equipos);
  return { rondas: [{ jornada: 1, partidos: partidos.map(([local, visitante]) => ({ local, visitante, fase })) }], directos };
};

/**
 * Reparte los partidos en fechas, horas y canchas.
 *  - Cada jornada empieza en un día nuevo; si no caben en un día, siguen en el siguiente día de juego.
 *  - Se salta lo que ya está ocupado: la misma sede a esa hora o un equipo que ya juega a esa hora.
 * opciones: { fechaInicio, dias:[0-6], horas:['16:00'], sedes:[id], simultaneos, ocupados:{ sedes:Set, equipos:Set }, hoy:{ fecha, hora } }
 */
export const programar = (rondas, { fechaInicio, dias, horas, sedes = [], simultaneos = 1, ocupados = { sedes: new Set(), equipos: new Set() }, hoy, horizonte = 400 }) => {
  const fechas = [];
  for (let i = 0; i < horizonte; i++) {
    const f = sumarDias(fechaInicio, i);
    if (dias.includes(diaSemana(f))) fechas.push(f);
  }
  const canchas = sedes.length ? sedes : Array.from({ length: simultaneos }, () => null);
  const usados = new Set();
  const resultado = [];
  let indiceFecha = 0;

  for (const ronda of rondas) {
    let i = indiceFecha;
    let ultimo = indiceFecha;
    for (const partido of ronda.partidos) {
      let colocado = false;
      while (!colocado) {
        if (i >= fechas.length) throw new Error('No alcanzan los días y horarios elegidos para programar todos los partidos. Agrega más días, horas o canchas.');
        const fecha = fechas[i];
        buscar: for (const hora of horas) {
          if (fecha === hoy.fecha && hora <= hoy.hora) continue; // lo de hoy que ya pasó no se programa
          for (let c = 0; c < canchas.length; c++) {
            const clave = `${fecha}|${hora}|${c}`;
            if (usados.has(clave)) continue;
            if (canchas[c] !== null && ocupados.sedes.has(`${fecha}|${hora}|${canchas[c]}`)) continue;
            if (ocupados.equipos.has(`${fecha}|${hora}|${partido.local}`) || ocupados.equipos.has(`${fecha}|${hora}|${partido.visitante}`)) continue;
            usados.add(clave);
            resultado.push({ ...partido, jornada: ronda.jornada, fecha, hora, lugar_id: canchas[c] });
            colocado = true;
            ultimo = Math.max(ultimo, i);
            break buscar;
          }
        }
        if (!colocado) i++;
      }
    }
    indiceFecha = ultimo + 1; // la siguiente jornada empieza otro día
  }
  return resultado;
};