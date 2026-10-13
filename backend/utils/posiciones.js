import { supabase } from '../config/supabase.js';
import { datos } from './helpers.js';

// Recalcula la tabla de posiciones de un torneo a partir de los partidos finalizados.
// Es idempotente: se puede llamar las veces que haga falta sin duplicar puntos.
export const recalcularTabla = async (torneo_id) => {
  const [inscritos, partidos] = await Promise.all([
    supabase.from('inscripciones_equipo').select('id, equipo_id').eq('torneo_id', torneo_id).eq('estado', 'Aceptado').then(datos),
    supabase.from('eventos_calendario')
      .select('equipo_local_id, equipo_visitante_id, resultado_local, resultado_visitante')
      .eq('torneo_id', torneo_id).eq('tipo', 'Partido').eq('estado', 'Finalizado').then(datos),
  ]);

  const filas = new Map(inscritos.map((i) => [i.equipo_id, {
    inscripcion_id: i.id, victorias: 0, empates: 0, derrotas: 0, goles_favor: 0, goles_contra: 0, puntos: 0,
  }]));

  const sumar = (fila, gf, gc) => {
    if (!fila) return;
    fila.goles_favor += gf;
    fila.goles_contra += gc;
    if (gf > gc) { fila.victorias++; fila.puntos += 3; }
    else if (gf === gc) { fila.empates++; fila.puntos += 1; }
    else fila.derrotas++;
  };

  for (const p of partidos) {
    if (p.resultado_local == null || p.resultado_visitante == null) continue;
    sumar(filas.get(p.equipo_local_id), p.resultado_local, p.resultado_visitante);
    sumar(filas.get(p.equipo_visitante_id), p.resultado_visitante, p.resultado_local);
  }

  // Desempate: puntos, diferencia de gol, goles a favor
  const ordenadas = [...filas.values()]
    .sort((a, b) => b.puntos - a.puntos || (b.goles_favor - b.goles_contra) - (a.goles_favor - a.goles_contra) || b.goles_favor - a.goles_favor)
    .map((f, i) => ({ ...f, posicion: i + 1 }));
  if (!ordenadas.length) return;

  // upsert por inscripcion_id (la fila existe o se crea)
  const existentes = new Set((await supabase.from('tabla_posiciones').select('inscripcion_id').in('inscripcion_id', ordenadas.map((f) => f.inscripcion_id)).then(datos)).map((f) => f.inscripcion_id));
  const nuevas = ordenadas.filter((f) => !existentes.has(f.inscripcion_id));
  if (nuevas.length) datos(await supabase.from('tabla_posiciones').insert(nuevas));
  await Promise.all(ordenadas.filter((f) => existentes.has(f.inscripcion_id)).map(async ({ inscripcion_id, ...cambios }) =>
    datos(await supabase.from('tabla_posiciones').update(cambios).eq('inscripcion_id', inscripcion_id))));
};

// La tabla es secundaria: si falla no debe tumbar la acción principal
export const recalcularSeguro = (torneo_id) => recalcularTabla(torneo_id).catch((e) => console.error('No se pudo recalcular la tabla de posiciones:', e.message));
