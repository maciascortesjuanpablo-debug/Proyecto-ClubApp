import 'api_client.dart';

/// Llamadas del panel de administración. Todas requieren rol Administrador (el backend lo verifica).
class AdminService {
  static Future<Map<String, dynamic>> _pedir(String metodo, String ruta, [Map<String, dynamic>? cuerpo]) =>
      ApiClient.pedir(metodo, ruta, cuerpo: cuerpo);

  // ---- Resumen ----
  static Future<Map<String, dynamic>> resumen() => _pedir('GET', '/admin/resumen');

  // ---- Usuarios ----
  static Future<Map<String, dynamic>> usuarios({String buscar = '', int? rol, bool? activo, int pagina = 0}) {
    final consulta = Uri(queryParameters: {'pagina': '$pagina', if (buscar.isNotEmpty) 'buscar': buscar, if (rol != null) 'rol': '$rol', if (activo != null) 'activo': '$activo'}).query;
    return _pedir('GET', '/admin/usuarios?$consulta');
  }

  static Future<Map<String, dynamic>> actualizarUsuario(Object id, Map<String, dynamic> cambios) => _pedir('PUT', '/admin/usuarios/$id', cambios);

  /// permanente=false solo desactiva la cuenta (reversible); true la borra con sus datos
  static Future<Map<String, dynamic>> eliminarUsuario(Object id, {bool permanente = false}) =>
      _pedir('DELETE', '/admin/usuarios/$id${permanente ? '?permanente=true' : ''}');

  // ---- Torneos ----
  static Future<Map<String, dynamic>> torneos() => _pedir('GET', '/admin/torneos');
  static Future<Map<String, dynamic>> actualizarTorneo(Object id, Map<String, dynamic> cambios) => _pedir('PUT', '/admin/torneos/$id', cambios);
  static Future<Map<String, dynamic>> eliminarTorneo(Object id) => _pedir('DELETE', '/admin/torneos/$id');

  // ---- Equipos ----
  static Future<Map<String, dynamic>> equipos() => _pedir('GET', '/admin/equipos');
  static Future<Map<String, dynamic>> eliminarEquipo(Object id) => _pedir('DELETE', '/admin/equipos/$id');
  static Future<Map<String, dynamic>> renombrarEquipo(Object id, String nombre) => _pedir('PUT', '/equipos/$id', {'nombre': nombre});
  static Future<Map<String, dynamic>> plantilla(Object equipoId) => _pedir('GET', '/equipos/$equipoId/jugadores');
  static Future<Map<String, dynamic>> quitarJugador(Object equipoId, Object usuarioId) => _pedir('DELETE', '/equipos/$equipoId/jugadores/$usuarioId');

  // ---- Inscripciones ----
  static Future<Map<String, dynamic>> inscripciones(String estado) => _pedir('GET', '/admin/inscripciones?estado=$estado');
  static Future<Map<String, dynamic>> resolverInscripcion(Object id, String estado) => _pedir('PUT', '/inscripciones/$id/estado', {'estado': estado});
}