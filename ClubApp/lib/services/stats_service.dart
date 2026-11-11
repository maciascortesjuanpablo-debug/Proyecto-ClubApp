import '../models/models.dart';
import 'api_client.dart';
import 'resultado.dart';

/// Estadísticas de jugadores en un partido
class StatsService {
  /// Lo registrado en un partido (público)
  static Future<Resultado<List<EstadisticaJugadorPartido>>> delPartido(Object eventoId) async {
    final r = await ApiClient.pedir('GET', '/estadisticas/evento/$eventoId');
    return r['exito'] == true ? Resultado.ok(toLista(r['datos']).map(EstadisticaJugadorPartido.fromJson).toList()) : Resultado.fallo(r['mensaje'].toString());
  }

  /// Guarda de una vez las estadísticas de los jugadores de uno o dos equipos (organizador, admin, árbitro asignado o entrenador del equipo).
  /// Cada fila: { usuario_id, equipo_id, goles, asistencias, tarjetas_amarillas, tarjetas_rojas, minutos_jugados }
  static Future<Map<String, dynamic>> guardar(Object eventoId, List<Map<String, dynamic>> jugadores) =>
      ApiClient.pedir('PUT', '/estadisticas/evento/$eventoId', cuerpo: {'jugadores': jugadores});
}