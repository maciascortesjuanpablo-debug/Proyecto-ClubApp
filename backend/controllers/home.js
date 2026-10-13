import { homeModel } from '../models/home.js';
import { usuarioModel } from '../models/usuario.js';
import { fallo } from '../utils/helpers.js';

const actividadPublica = async () => {
  const [resultados, torneos] = await Promise.all([
    homeModel.ultimosResultados(3),
    homeModel.ultimosTorneos(3)
  ]);

  return [
    ...resultados.map(p => ({
      tipo: 'resultado',
      titulo: `${p.equipo_local?.nombre ?? 'Local'} ${p.resultado_local ?? 0}-${p.resultado_visitante ?? 0} ${p.equipo_visitante?.nombre ?? 'Visitante'}`,
      fecha: p.creado_en
    })),
    ...torneos.map(t => ({ tipo: 'torneo', titulo: `Nuevo torneo: ${t.nombre}`, fecha: t.creado_en }))
  ];
};

const ordenarYCortar = (items, limite) =>
  items.sort((a, b) => new Date(b.fecha) - new Date(a.fecha)).slice(0, limite);

const datosPublicos = async () => {
  const [partidoEnVivo, partidosDestacados, torneosActivos, actividad] = await Promise.all([
    homeModel.partidoEnVivo(),
    homeModel.partidosDestacados(6),
    homeModel.torneosActivos(5),
    actividadPublica()
  ]);
  return { partidoEnVivo, partidosDestacados, torneosActivos, actividad };
};

// GET /api/home/publico  (invitado, sin token)
export const obtenerHomePublico = async (req, res) => {
  try {
    const { actividad, ...resto } = await datosPublicos();
    res.json({ ...resto, actividadReciente: ordenarYCortar(actividad, 5) });
  } catch (error) {
    fallo(res, error, 'Error al cargar el inicio');
  }
};

// GET /api/home  (logueado, con token)
export const obtenerHomeUsuario = async (req, res) => {
  try {
    const usuarioId = req.usuario.id;

    const [publicos, usuario, estadisticas, noLeidas, notificaciones] = await Promise.all([
      datosPublicos(),
      usuarioModel.buscarPorId(usuarioId),
      homeModel.estadisticasUsuario(usuarioId),
      homeModel.notificacionesNoLeidas(usuarioId),
      homeModel.notificacionesRecientes(usuarioId, 5)
    ]);

    if (!usuario) {
      return res.status(404).json({ mensaje: 'Usuario no encontrado' });
    }

    const { actividad, ...resto } = publicos;
    const personales = notificaciones.map(n => ({ tipo: 'notificacion', titulo: n.titulo, fecha: n.creado_en }));

    res.json({
      usuario: { id: usuario.id, nombre: usuario.nombre, apellido: usuario.apellido, rol_id: usuario.rol_id },
      ...resto,
      estadisticas,
      notificacionesNoLeidas: noLeidas,
      actividadReciente: ordenarYCortar([...personales, ...actividad], 6)
    });
  } catch (error) {
    fallo(res, error, 'Error al cargar el inicio');
  }
};