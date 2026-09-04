import Groq from "groq-sdk";
import { supabase } from "../config/supabase.js"; // Ajusta la ruta a tu cliente de Supabase existente

const groq = new Groq({ apiKey: process.env.GROQ_API_KEY });

/* ============================================================
   1. CHAT CON SCOUT AI
   Endpoint conversacional. Crea o continua una conversacion,
   consulta jugadores/torneos activos como contexto, y guarda
   cada mensaje (usuario y asistente) en la tabla "mensajes".
   ============================================================ */
export const chatConScout = async (req, res) => {
  try {
    const { mensaje, conversacionId, usuarioId } = req.body;

    if (!mensaje || !mensaje.trim()) {
      return res.status(400).json({ message: "Debes enviar un mensaje." });
    }
    if (!usuarioId) {
      return res.status(400).json({ message: "Debes enviar el usuarioId." });
    }

    // 1. Obtener o crear la conversacion
    let idConversacion = conversacionId;

    if (!idConversacion) {
      const { data: nuevaConversacion, error: errorCrear } = await supabase
        .from("scout_ai_conversaciones")
        .insert({
          usuario_id: usuarioId,
          titulo: mensaje.trim().slice(0, 60),
        })
        .select("id")
        .single();

      if (errorCrear) {
        console.error("Error creando conversacion:", errorCrear);
        return res.status(500).json({
          message: "Error al crear la conversacion.",
          detalle: errorCrear.message,
          codigo: errorCrear.code,
          hint: errorCrear.hint,
        });
      }
      idConversacion = nuevaConversacion.id;
    }

    // 2. Traer el historial reciente de esta conversacion (para darle memoria al modelo)
    const { data: historialPrevio, error: errorHistorial } = await supabase
      .from("mensajes")
      .select("rol, contenido")
      .eq("conversacion_id", idConversacion)
      .order("creado_en", { ascending: true })
      .limit(20);

    if (errorHistorial) {
      console.error("Error consultando historial:", errorHistorial.message);
    }

    // 3. Traer contexto real: jugadores disponibles y torneos activos
    //    Ajusta los nombres de columnas si tus tablas "jugadores" / "torneos" son distintas.
    const { data: jugadores, error: errorJugadores } = await supabase
      .from("jugadores")
      .select("id, nombre, posicion, edad, equipo_id")
      .limit(50);

    const { data: torneos, error: errorTorneos } = await supabase
      .from("torneos")
      .select("id, nombre, categoria, fecha_inicio, fecha_fin")
      .limit(20);

    if (errorJugadores) console.error("Error consultando jugadores:", errorJugadores.message);
    if (errorTorneos) console.error("Error consultando torneos:", errorTorneos.message);

    const listaJugadores = (jugadores || [])
      .map((j) => `- [id:${j.id}] ${j.nombre} | Posicion: ${j.posicion} | Edad: ${j.edad} | Equipo: ${j.equipo_id}`)
      .join("\n") || "No hay jugadores registrados todavia.";

    const listaTorneos = (torneos || [])
      .map((t) => `- [id:${t.id}] ${t.nombre} | Categoria: ${t.categoria} | ${t.fecha_inicio} a ${t.fecha_fin}`)
      .join("\n") || "No hay torneos registrados todavia.";

    const systemPrompt = `
Eres "Scout AI", el asistente virtual de ClubApp para analisis deportivo.
Ayudas a directores tecnicos y organizadores a encontrar jugadores para torneos,
comparar rendimiento y responder dudas sobre los equipos y campeonatos registrados.
Siempre con un lenguaje cordial, profesional y conciso. Nunca inventes jugadores ni torneos, solo usa los datos reales listados abajo.

JUGADORES DISPONIBLES:
${listaJugadores}

TORNEOS REGISTRADOS:
${listaTorneos}

REGLAS:
1. Si el usuario solo saluda, responde con cordialidad breve, sin listar datos.
2. Cuando recomiendes un jugador, basate SOLO en los datos reales listados arriba, nunca inventes jugadores.
3. Si te piden una recomendacion para un torneo especifico, prioriza jugadores cuya posicion y edad encajen con la categoria del torneo.
4. Se claro y conciso, en espanol.
`;

    const mensajesParaGroq = [
      { role: "system", content: systemPrompt },
      ...(historialPrevio || []).map((m) => ({
        role: m.rol === "asistente" ? "assistant" : m.rol,
        content: m.contenido,
      })),
      { role: "user", content: mensaje },
    ];

    // 4. Inferencia con Groq
    const completion = await groq.chat.completions.create({
      model: "openai/gpt-oss-20b",
      messages: mensajesParaGroq,
      temperature: 0.3,
      max_tokens: 600,
    });

    const respuestaTexto =
      completion.choices[0]?.message?.content || "No pude generar una respuesta.";

    // 5. Guardar pregunta y respuesta en "mensajes"
    const { error: errorInsertMensajes } = await supabase.from("mensajes").insert([
      { conversacion_id: idConversacion, rol: "user", contenido: mensaje.trim() },
      { conversacion_id: idConversacion, rol: "asistente", contenido: respuestaTexto },
    ]);

    if (errorInsertMensajes) {
      console.error("Error guardando mensajes:", errorInsertMensajes.message);
    }

    // 6. Actualizar la marca de tiempo de la conversacion
    await supabase
      .from("scout_ai_conversaciones")
      .update({ actualizado_en: new Date().toISOString() })
      .eq("id", idConversacion);

    return res.status(200).json({
      respuesta: respuestaTexto,
      conversacionId: idConversacion,
    });
  } catch (error) {
    console.error("Error en Scout AI chat:", error);
    return res.status(500).json({ message: "Error al procesar la respuesta", error: error.message });
  }
};

/* ============================================================
   2. HISTORIAL DE UNA CONVERSACION
   ============================================================ */
export const obtenerHistorialScout = async (req, res) => {
  try {
    const { conversacionId } = req.params;

    const { data: historial, error } = await supabase
      .from("mensajes")
      .select("rol, contenido, creado_en")
      .eq("conversacion_id", conversacionId)
      .order("creado_en", { ascending: true });

    if (error) {
      return res.status(500).json({ message: "Error al consultar historial", error: error.message });
    }

    return res.status(200).json({ historial: historial || [] });
  } catch (error) {
    return res.status(500).json({ message: "Error interno", error: error.message });
  }
};

/* ============================================================
   3. RECOMENDAR JUGADOR PARA UN TORNEO
   Genera una recomendacion puntual con Groq y la guarda en
   "scout_ai_recomendaciones" (queda asociada a la conversacion).
   ============================================================ */
export const recomendarJugador = async (req, res) => {
  try {
    const { conversacionId, solicitadoPor, torneoId } = req.body;

    if (!solicitadoPor || !torneoId) {
      return res.status(400).json({ message: "Debes enviar solicitadoPor y torneoId." });
    }

    const { data: torneo, error: errorTorneo } = await supabase
      .from("torneos")
      .select("id, nombre, categoria")
      .eq("id", torneoId)
      .single();

    if (errorTorneo || !torneo) {
      return res.status(404).json({ message: "Torneo no encontrado." });
    }

    const { data: jugadores, error: errorJugadores } = await supabase
      .from("jugadores")
      .select("id, nombre, posicion, edad")
      .limit(50);

    if (errorJugadores) {
      return res.status(500).json({ message: "Error al consultar jugadores." });
    }

    const listaJugadores = (jugadores || [])
      .map((j) => `- [id:${j.id}] ${j.nombre} | Posicion: ${j.posicion} | Edad: ${j.edad}`)
      .join("\n");

    const prompt = `
Eres Scout AI. Analiza esta lista de jugadores y elige el MEJOR candidato para el torneo "${torneo.nombre}" (categoria: ${torneo.categoria}).

JUGADORES:
${listaJugadores}

Responde UNICAMENTE en formato JSON, sin texto adicional, con esta forma exacta:
{"jugadorId": "<id del jugador elegido>", "motivo": "<explicacion breve>", "puntajeAfinidad": <numero entre 0 y 100>}
`;

    const completion = await groq.chat.completions.create({
      model: "openai/gpt-oss-20b",
      messages: [{ role: "user", content: prompt }],
      temperature: 0.2,
      max_tokens: 300,
    });

    const textoBruto = completion.choices[0]?.message?.content || "{}";
    const textoLimpio = textoBruto.replace(/```json|```/g, "").trim();

    let resultado;
    try {
      resultado = JSON.parse(textoLimpio);
    } catch (parseError) {
      console.error("La IA no devolvio JSON valido:", textoBruto);
      return res.status(502).json({ message: "La IA no devolvio una recomendacion valida." });
    }

    const { data: recomendacion, error: errorInsert } = await supabase
      .from("scout_ai_recomendaciones")
      .insert({
        conversacion_id: conversacionId || null,
        solicitado_por: solicitadoPor,
        jugador_recomendado_id: resultado.jugadorId,
        torneo_id: torneoId,
        motivo: resultado.motivo,
        puntaje_afinidad: resultado.puntajeAfinidad,
      })
      .select()
      .single();

    if (errorInsert) {
      console.error("Error guardando recomendacion:", errorInsert.message);
      return res.status(500).json({ message: "Error al guardar la recomendacion." });
    }

    return res.status(200).json({ recomendacion });
  } catch (error) {
    console.error("Error en recomendarJugador:", error);
    return res.status(500).json({ message: "Error al procesar la recomendacion", error: error.message });
  }
};

/* ============================================================
   4. GENERAR REPORTE DE EQUIPO
   Genera un reporte de texto (rendimiento, resumen, etc) para un
   equipo en un periodo, y lo guarda en "scout_ai_reportes".
   ============================================================ */
export const generarReporteEquipo = async (req, res) => {
  try {
    const { solicitadoPor, usuarioId, equipoId, tipo, periodoInicio, periodoFin } = req.body;

    if (!solicitadoPor || !equipoId || !tipo) {
      return res.status(400).json({ message: "Debes enviar solicitadoPor, equipoId y tipo." });
    }

    const { data: equipo, error: errorEquipo } = await supabase
      .from("equipos")
      .select("id, nombre")
      .eq("id", equipoId)
      .single();

    if (errorEquipo || !equipo) {
      return res.status(404).json({ message: "Equipo no encontrado." });
    }

    const { data: jugadoresEquipo, error: errorJugadores } = await supabase
      .from("jugadores")
      .select("nombre, posicion, edad")
      .eq("equipo_id", equipoId);

    if (errorJugadores) console.error("Error consultando jugadores del equipo:", errorJugadores.message);

    const listaJugadores = (jugadoresEquipo || [])
      .map((j) => `- ${j.nombre} (${j.posicion}, ${j.edad} anios)`)
      .join("\n") || "Sin jugadores registrados para este equipo.";

    const prompt = `
Eres Scout AI. Redacta un reporte tipo "${tipo}" para el equipo "${equipo.nombre}"${
      periodoInicio && periodoFin ? ` correspondiente al periodo ${periodoInicio} a ${periodoFin}` : ""
    }.

PLANTILLA DE JUGADORES DEL EQUIPO:
${listaJugadores}

El reporte debe ser breve (maximo 200 palabras), en espanol, con un tono profesional
y basado unicamente en los datos entregados. Si faltan datos, aclaralo en vez de inventar cifras.
`;

    const completion = await groq.chat.completions.create({
      model: "openai/gpt-oss-20b",
      messages: [{ role: "user", content: prompt }],
      temperature: 0.4,
      max_tokens: 500,
    });

    const contenidoReporte =
      completion.choices[0]?.message?.content || "No fue posible generar el reporte.";

    const { data: reporte, error: errorInsert } = await supabase
      .from("scout_ai_reportes")
      .insert({
        solicitado_por: solicitadoPor,
        usuario_id: usuarioId || null,
        equipo_id: equipoId,
        tipo,
        contenido: contenidoReporte,
        periodo_inicio: periodoInicio || null,
        periodo_fin: periodoFin || null,
      })
      .select()
      .single();

    if (errorInsert) {
      console.error("Error guardando reporte:", errorInsert.message);
      return res.status(500).json({ message: "Error al guardar el reporte." });
    }

    return res.status(200).json({ reporte });
  } catch (error) {
    console.error("Error en generarReporteEquipo:", error);
    return res.status(500).json({ message: "Error al generar el reporte", error: error.message });
  }
};