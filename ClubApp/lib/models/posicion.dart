import 'json_utils.dart';

/// Una fila de la tabla de posiciones de un torneo
class FilaPosicion {
  final int posicion;
  final Object? equipoId;
  final String equipo;
  final String? logoUrl;
  final int victorias, empates, derrotas, golesFavor, golesContra, puntos;

  const FilaPosicion({
    required this.posicion,
    this.equipoId,
    required this.equipo,
    this.logoUrl,
    this.victorias = 0,
    this.empates = 0,
    this.derrotas = 0,
    this.golesFavor = 0,
    this.golesContra = 0,
    this.puntos = 0,
  });

  factory FilaPosicion.fromJson(Map<String, dynamic> j) {
    final eq = toMap(toMap(j['inscripciones_equipo'])['equipos']);
    return FilaPosicion(
      posicion: toInt(j['posicion']),
      equipoId: eq['id'] as Object?,
      equipo: toStr(eq['nombre'], 'Equipo'),
      logoUrl: toStrN(eq['logo_url']),
      victorias: toInt(j['victorias']),
      empates: toInt(j['empates']),
      derrotas: toInt(j['derrotas']),
      golesFavor: toInt(j['goles_favor']),
      golesContra: toInt(j['goles_contra']),
      puntos: toInt(j['puntos']),
    );
  }

  int get jugados => victorias + empates + derrotas;
  int get diferencia => golesFavor - golesContra;
}
