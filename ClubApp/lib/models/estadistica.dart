import 'json_utils.dart';

/// Estadísticas de un jugador en un partido (tabla `estadisticas_jugador`)
class EstadisticaPartido {
  final DateTime? fecha;
  final int goles, asistencias, amarillas, rojas, minutos;

  const EstadisticaPartido({this.fecha, this.goles = 0, this.asistencias = 0, this.amarillas = 0, this.rojas = 0, this.minutos = 0});

  factory EstadisticaPartido.fromJson(Map<String, dynamic> j) => EstadisticaPartido(
        fecha: toFecha(j['fecha']),
        goles: toInt(j['goles']),
        asistencias: toInt(j['asistencias']),
        amarillas: toInt(j['tarjetas_amarillas']),
        rojas: toInt(j['tarjetas_rojas']),
        minutos: toInt(j['minutos_jugados']),
      );
}

/// Totales de un jugador (solo existen para el rol Jugador)
class EstadisticasJugador {
  final int partidos, goles, asistencias, amarillas, rojas, minutos;

  const EstadisticasJugador({this.partidos = 0, this.goles = 0, this.asistencias = 0, this.amarillas = 0, this.rojas = 0, this.minutos = 0});

  factory EstadisticasJugador.fromJson(Map<String, dynamic> j) => EstadisticasJugador(
        partidos: toInt(j['partidos']),
        goles: toInt(j['goles']),
        asistencias: toInt(j['asistencias']),
        amarillas: toInt(j['tarjetas_amarillas']),
        rojas: toInt(j['tarjetas_rojas']),
        minutos: toInt(j['minutos']),
      );

  double get golesPorPartido => partidos == 0 ? 0 : goles / partidos;
  int get tarjetas => amarillas + rojas;
}
