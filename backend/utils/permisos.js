import { esAdmin, esMismoUsuario } from './helpers.js';

// Equipos sin `creado_por` (creados antes de la migración) quedan abiertos a los roles que ya podían editarlos
export const esDuenoEquipo = (req, equipo) => esAdmin(req) || !equipo.creado_por || esMismoUsuario(req, equipo.creado_por);

export const esOrganizadorTorneo = (req, torneo) => esAdmin(req) || (!!torneo.organizador_id && esMismoUsuario(req, torneo.organizador_id));
