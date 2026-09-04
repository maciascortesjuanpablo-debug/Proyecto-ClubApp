import express from "express";
import {
  chatConScout,
  obtenerHistorialScout,
  recomendarJugador,
  generarReporteEquipo,
} from "../controllers/scouthIA.js";

const router = express.Router();

// Chat conversacional con Scout AI
router.post("/chat", chatConScout);

// Historial de mensajes de una conversacion
router.get("/chat/historial/:conversacionId", obtenerHistorialScout);

// Recomendacion de jugador para un torneo especifico
router.post("/recomendaciones", recomendarJugador);

// Generacion de reportes de equipo
router.post("/reportes", generarReporteEquipo);

export default router;