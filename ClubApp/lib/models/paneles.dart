import 'equipo.dart';
import 'estadistica.dart';
import 'json_utils.dart';
import 'partido.dart';
import 'torneo.dart';
import 'usuario.dart';

List<Partido> _partidos(dynamic v) => toLista(v).map(Partido.fromJson).toList();

/// Panel del JUGADOR: su equipo, su próximo partido y sus estadísticas de juego
class PanelJugador {
  final PerfilJugador? perfil;
  final List<Equipo> equipos;
  final List<Partido> proximos;
  final EstadisticasJugador estadisticas;
  final List<EstadisticaPartido> ultimosPartidos;
  final List<Invitacion> invitaciones;

  const PanelJugador({this.perfil, this.equipos = const [], this.proximos = const [], this.estadisticas = const EstadisticasJugador(), this.ultimosPartidos = const [], this.invitaciones = const []});

  factory PanelJugador.fromJson(Map<String, dynamic> j) => PanelJugador(
        perfil: j['perfil'] is Map ? PerfilJugador.fromJson(toMap(j['perfil'])) : null,
        equipos: toLista(j['equipos']).map(Equipo.fromJson).toList(),
        proximos: _partidos(j['proximosPartidos']),
        estadisticas: EstadisticasJugador.fromJson(toMap(j['estadisticas'])),
        ultimosPartidos: toLista(j['ultimosPartidos']).map(EstadisticaPartido.fromJson).toList(),
        invitaciones: toLista(j['invitaciones']).map(Invitacion.fromJson).toList(),
      );

  Equipo? get equipoPrincipal => equipos.isEmpty ? null : equipos.first;
}

/// Panel del ENTRENADOR: sus equipos, plantillas e inscripciones
class PanelEntrenador {
  final List<Equipo> equipos;
  final List<Partido> proximos;
  final int invitacionesPendientes;
  final int totalEquipos, totalJugadores, torneosActivos, inscripcionesPendientes;

  const PanelEntrenador({this.equipos = const [], this.proximos = const [], this.invitacionesPendientes = 0, this.totalEquipos = 0, this.totalJugadores = 0, this.torneosActivos = 0, this.inscripcionesPendientes = 0});

  factory PanelEntrenador.fromJson(Map<String, dynamic> j) {
    final t = toMap(j['totales']);
    return PanelEntrenador(
      equipos: toLista(j['equipos']).map(Equipo.fromJson).toList(),
      proximos: _partidos(j['proximosPartidos']),
      invitacionesPendientes: toInt(j['invitacionesPendientes']),
      totalEquipos: toInt(t['equipos']),
      totalJugadores: toInt(t['jugadores']),
      torneosActivos: toInt(t['torneosActivos']),
      inscripcionesPendientes: toInt(t['inscripcionesPendientes']),
    );
  }
}

/// Un torneo del organizador con sus cifras
class TorneoGestionado {
  final Torneo torneo;
  final int equiposAceptados, equiposPendientes, partidosTotal, partidosJugados;

  const TorneoGestionado({required this.torneo, this.equiposAceptados = 0, this.equiposPendientes = 0, this.partidosTotal = 0, this.partidosJugados = 0});

  factory TorneoGestionado.fromJson(Map<String, dynamic> j) => TorneoGestionado(
        torneo: Torneo.fromJson(j),
        equiposAceptados: toInt(j['equipos_aceptados']),
        equiposPendientes: toInt(j['equipos_pendientes']),
        partidosTotal: toInt(j['partidos_total']),
        partidosJugados: toInt(j['partidos_jugados']),
      );

  double get avance => partidosTotal == 0 ? 0 : partidosJugados / partidosTotal;
}

/// Panel del ORGANIZADOR: sus torneos, inscripciones por resolver y partidos por programar
class PanelOrganizador {
  final List<TorneoGestionado> torneos;
  final List<Inscripcion> pendientes;
  final List<Partido> proximos;
  final int sinArbitro, totalTorneos, totalEquipos, partidosHoy, partidosSemana;

  const PanelOrganizador({this.torneos = const [], this.pendientes = const [], this.proximos = const [], this.sinArbitro = 0, this.totalTorneos = 0, this.totalEquipos = 0, this.partidosHoy = 0, this.partidosSemana = 0});

  factory PanelOrganizador.fromJson(Map<String, dynamic> j) {
    final t = toMap(j['totales']);
    return PanelOrganizador(
      torneos: toLista(j['torneos']).map(TorneoGestionado.fromJson).toList(),
      pendientes: toLista(j['inscripcionesPendientes']).map(Inscripcion.fromJson).toList(),
      proximos: _partidos(j['proximosPartidos']),
      sinArbitro: toInt(j['sinArbitro']),
      totalTorneos: toInt(t['torneos']),
      totalEquipos: toInt(t['equipos']),
      partidosHoy: toInt(t['partidosHoy']),
      partidosSemana: toInt(t['partidosSemana']),
    );
  }
}

/// Panel del ÁRBITRO: sus designaciones y lo que pasó en los partidos que dirigió (no tiene estadísticas de jugador)
class PanelArbitro {
  final List<Partido> hoy;
  final List<Partido> proximos;
  final List<Partido> recientes;
  final int asignados, dirigidos, porDirigir, amarillas, rojas, goles;
  final List<Torneo> torneos;

  const PanelArbitro({this.hoy = const [], this.proximos = const [], this.recientes = const [], this.asignados = 0, this.dirigidos = 0, this.porDirigir = 0, this.amarillas = 0, this.rojas = 0, this.goles = 0, this.torneos = const []});

  factory PanelArbitro.fromJson(Map<String, dynamic> j) {
    final t = toMap(j['totales']);
    return PanelArbitro(
      hoy: _partidos(j['hoy']),
      proximos: _partidos(j['proximos']),
      recientes: _partidos(j['recientes']),
      asignados: toInt(t['asignados']),
      dirigidos: toInt(t['dirigidos']),
      porDirigir: toInt(t['proximos']),
      amarillas: toInt(t['tarjetas_amarillas']),
      rojas: toInt(t['tarjetas_rojas']),
      goles: toInt(t['goles']),
      torneos: toLista(j['torneos']).map(Torneo.fromJson).toList(),
    );
  }

  int get tarjetas => amarillas + rojas;
}
