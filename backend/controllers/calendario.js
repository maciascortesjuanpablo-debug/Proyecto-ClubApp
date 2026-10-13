import { calendarioModel } from '../models/calendario.js';
import { torneoModel } from '../models/torneos.js';
import { inscripcionModel } from '../models/inscripciones.js';
import { FECHA_RE, HORA_RE, entero, fallo, pick, texto } from '../utils/helpers.js';
import { esOrganizadorTorneo } from '../utils/permisos.js';
import { recalcularSeguro } from '../utils/posiciones.js';

// Carga el torneo y comprueba que el usuario lo organiza; responde 404/403 y devuelve null si no
const torneoGestionable = async (req, res, torneo_id) => {
  const torneo = torneo_id ? await torneoModel.buscarPorId(torneo_id) : null;
  if (!torneo) return void res.status(404).json({ mensaje: 'Torneo no encontrado' });
  if (!esOrganizadorTorneo(req, torneo)) return void res.status(403).json({ mensaje: 'No organizas este torneo' });
  return torneo;
};

// Middleware: carga el evento de :id y exige ser organizador de su torneo
export const eventoGestionable = async (req, res, next) => {
  try {
    const evento = await calendarioModel.buscarPorId(req.params.id);
    if (!evento) return res.status(404).json({ mensaje: 'Evento no encontrado' });
    if (!(await torneoGestionable(req, res, evento.torneo_id))) return;
    req.evento = evento;
    next();
  } catch (error) {
    fallo(res, error, 'Error al verificar el evento');
  }
};

export const crearSede = async (req, res) => {
  try {
    const nombre = texto(req.body.nombre, 120);
    if (!nombre) return res.status(400).json({ mensaje: 'El nombre de la sede es obligatorio' });
    const sede = await calendarioModel.crearSede({ nombre, direccion: texto(req.body.direccion, 200) || null, ciudad: texto(req.body.ciudad) || null });
    res.status(201).json({ mensaje: 'Sede creada', sede });
  } catch (error) {
    fallo(res, error, 'Error al crear la sede');
  }
};

export const obtenerSedes = async (req, res) => {
  try {
    res.json(await calendarioModel.listarSedes());
  } catch (error) {
    fallo(res, error, 'Error al obtener las sedes');
  }
};

export const crearEvento = async (req, res) => {
  try {
    const { torneo_id, tipo, equipo_local_id, equipo_visitante_id, fecha, hora, lugar_id } = req.body;
    if (!torneo_id || !tipo || !fecha || !hora) {
      return res.status(400).json({ mensaje: 'torneo_id, tipo, fecha y hora son obligatorios' });
    }
    if (!FECHA_RE.test(fecha) || !HORA_RE.test(hora)) {
      return res.status(400).json({ mensaje: 'La fecha debe ser AAAA-MM-DD y la hora HH:MM' });
    }
    if (!(await torneoGestionable(req, res, torneo_id))) return;

    if (tipo === 'Partido') {
      if (!equipo_local_id || !equipo_visitante_id || String(equipo_local_id) === String(equipo_visitante_id)) {
        return res.status(400).json({ mensaje: 'Un partido necesita dos equipos distintos' });
      }
      const aceptados = (await inscripcionModel.equiposAceptados(torneo_id)).map(String);
      if (![equipo_local_id, equipo_visitante_id].every((e) => aceptados.includes(String(e)))) {
        return res.status(400).json({ mensaje: 'Ambos equipos deben estar aceptados en el torneo' });
      }
    }

    const evento = await calendarioModel.crearEvento({ torneo_id, tipo, equipo_local_id, equipo_visitante_id, fecha, hora, lugar_id });
    res.status(201).json({ mensaje: 'Evento creado', evento });
  } catch (error) {
    fallo(res, error, 'Error al crear el evento');
  }
};

export const obtenerEventosPorTorneo = async (req, res) => {
  try {
    res.json(await calendarioModel.listarPorTorneo(req.params.torneoId));
  } catch (error) {
    fallo(res, error, 'Error al obtener los eventos');
  }
};

export const obtenerEventoPorId = async (req, res) => {
  try {
    const evento = await calendarioModel.buscarPorId(req.params.id);
    if (!evento) return res.status(404).json({ mensaje: 'Evento no encontrado' });
    res.json(evento);
  } catch (error) {
    fallo(res, error, 'Error al obtener el evento');
  }
};

export const actualizarEvento = async (req, res) => {
  try {
    const cambios = pick(req.body, ['tipo', 'equipo_local_id', 'equipo_visitante_id', 'fecha', 'hora', 'lugar_id', 'estado', 'resultado_local', 'resultado_visitante']);
    if (!Object.keys(cambios).length) return res.status(400).json({ mensaje: 'No hay campos válidos para actualizar' });
    if ((cambios.fecha && !FECHA_RE.test(cambios.fecha)) || (cambios.hora && !HORA_RE.test(cambios.hora))) {
      return res.status(400).json({ mensaje: 'La fecha debe ser AAAA-MM-DD y la hora HH:MM' });
    }
    for (const c of ['resultado_local', 'resultado_visitante']) {
      if (cambios[c] != null && (cambios[c] = entero(cambios[c], 0, 99)) === null) {
        return res.status(400).json({ mensaje: 'Los resultados deben ser enteros entre 0 y 99' });
      }
    }
    const evento = await calendarioModel.actualizar(req.params.id, cambios);
    await recalcularSeguro(req.evento.torneo_id); // los resultados cambian la tabla de posiciones
    res.json({ mensaje: 'Evento actualizado', evento });
  } catch (error) {
    fallo(res, error, 'Error al actualizar el evento');
  }
};

export const eliminarEvento = async (req, res) => {
  try {
    await calendarioModel.eliminar(req.params.id);
    await recalcularSeguro(req.evento.torneo_id);
    res.json({ mensaje: 'Evento eliminado' });
  } catch (error) {
    fallo(res, error, 'Error al eliminar el evento');
  }
};

export const asignarArbitro = async (req, res) => {
  try {
    const { usuario_id, rol_arbitraje } = req.body;
    if (!usuario_id) return res.status(400).json({ mensaje: 'usuario_id es obligatorio' });
    if (await calendarioModel.esArbitroDelEvento(req.params.id, usuario_id)) {
      return res.status(409).json({ mensaje: 'Ese árbitro ya está asignado al evento' });
    }
    const arbitro = await calendarioModel.asignarArbitro({ evento_id: req.params.id, usuario_id, rol_arbitraje: rol_arbitraje || 'Principal' });
    res.status(201).json({ mensaje: 'Árbitro asignado', arbitro });
  } catch (error) {
    fallo(res, error, 'Error al asignar el árbitro');
  }
};

export const obtenerArbitrosPorEvento = async (req, res) => {
  try {
    res.json(await calendarioModel.listarArbitrosPorEvento(req.params.id));
  } catch (error) {
    fallo(res, error, 'Error al obtener los árbitros');
  }
};
