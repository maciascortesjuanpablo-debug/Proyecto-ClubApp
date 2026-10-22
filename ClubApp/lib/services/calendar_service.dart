import 'api_client.dart';
import 'auth_service.dart';
import '../core/calendar_utils.dart';

/// Llamadas del calendario. Todas devuelven {exito, mensaje, ...datos} (las listas llegan en 'datos').
class CalendarService {
  static Future<Map<String, dynamic>> _pedir(String metodo, String ruta, [Map<String, dynamic>? cuerpo]) =>
      ApiClient.pedir(metodo, ruta, cuerpo: cuerpo);

  /// Eventos entre dos fechas (incluidas). `mios` = solo donde juega mi equipo, soy árbitro u organizo. Respuesta: 'eventos'
  static Future<Map<String, dynamic>> eventos(DateTime desde, DateTime hasta, {bool mios = false}) =>
      _pedir('GET', '/calendario/${mios ? 'mis-eventos' : 'eventos'}?desde=${isoFecha(desde)}&hasta=${isoFecha(hasta)}');

  /// Detalle: el evento con su 'torneo' y sus 'arbitros'
  static Future<Map<String, dynamic>> evento(Object id) => _pedir('GET', '/calendario/eventos/$id');

  static Future<Map<String, dynamic>> crearEvento(Map<String, dynamic> datos) => _pedir('POST', '/calendario/eventos', datos);
  static Future<Map<String, dynamic>> actualizarEvento(Object id, Map<String, dynamic> datos) => _pedir('PUT', '/calendario/eventos/$id', datos);
  static Future<Map<String, dynamic>> eliminarEvento(Object id) => _pedir('DELETE', '/calendario/eventos/$id');

  /// Estado y marcador (organizador, admin o árbitro asignado). La tabla de posiciones se actualiza sola.
  static Future<Map<String, dynamic>> registrarResultado(Object id, {String? estado, int? local, int? visitante}) => _pedir('PUT', '/calendario/eventos/$id/resultado', {
        if (estado != null) 'estado': estado,
        if (local != null) 'resultado_local': local,
        if (visitante != null) 'resultado_visitante': visitante,
      });

  // ---- Sedes ----
  static Future<Map<String, dynamic>> sedes() => _pedir('GET', '/calendario/sedes');
  static Future<Map<String, dynamic>> crearSede({required String nombre, String direccion = '', String ciudad = ''}) =>
      _pedir('POST', '/calendario/sedes', {'nombre': nombre, 'direccion': direccion, 'ciudad': ciudad});


  // ---- Árbitros ----
  static Future<Map<String, dynamic>> arbitrosDisponibles() => _pedir('GET', '/calendario/arbitros'); // 'arbitros'
  static Future<Map<String, dynamic>> asignarArbitro(Object eventoId, Object usuarioId) => _pedir('POST', '/calendario/eventos/$eventoId/arbitros', {'usuario_id': usuarioId});
  static Future<Map<String, dynamic>> quitarArbitro(Object eventoId, Object filaId) => _pedir('DELETE', '/calendario/eventos/$eventoId/arbitros/$filaId');

  // ---- Datos para el formulario ----
  /// Torneos donde se pueden crear eventos: todos para el admin, los propios para el organizador (en 'datos')
  static Future<Map<String, dynamic>> torneosGestionables() =>
      miRol == 6 ? _pedir('GET', '/torneos') : _pedir('GET', '/torneos/organizador/${AuthService.usuario?['id']}');

  /// Equipos aceptados en un torneo, como lista de {id, nombre, logo_url} en 'equipos'
  static Future<Map<String, dynamic>> equiposAceptados(Object torneoId) async {
    final r = await _pedir('GET', '/inscripciones/torneo/$torneoId');
    if (r['exito'] != true) return r;
    final equipos = (r['datos'] as List).cast<Map<String, dynamic>>().where((i) => i['estado'] == 'Aceptado' && i['equipos'] != null).map((i) => i['equipos'] as Map<String, dynamic>).toList();
    return {'exito': true, 'equipos': equipos};
  }
}