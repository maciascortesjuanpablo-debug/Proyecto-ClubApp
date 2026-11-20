import { esAdmin, esMismoUsuario } from './helpers.js';

// Un equipo sin `creado_por` (huérfano) solo lo gestiona un Admin: nunca queda abierto a cualquier entrenador
export const esDuenoEquipo = (req, equipo) => esAdmin(req) || (!!equipo.creado_por && esMismoUsuario(req, equipo.creado_por));

export const esOrganizadorTorneo = (req, torneo) => esAdmin(req) || (!!torneo.organizador_id && esMismoUsuario(req, torneo.organizador_id));
