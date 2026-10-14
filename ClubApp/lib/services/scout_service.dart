import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/app_constants.dart';
import 'auth_service.dart';

/// Cliente de /api/scout. Todas las respuestas son {exito, mensaje, ...datos}
class ScoutService {
  static Future<Map<String, dynamic>> _pedir(String metodo, String ruta, {Map<String, dynamic>? cuerpo, int segundos = 15}) async {
    try {
      final uri = Uri.parse('${AppConfig.apiUrl}/scout$ruta');
      final headers = {'Content-Type': 'application/json', 'Authorization': 'Bearer ${AuthService.token}'};
      final peticion = switch (metodo) {
        'POST' => http.post(uri, headers: headers, body: jsonEncode(cuerpo)),
        'PUT' => http.put(uri, headers: headers, body: jsonEncode(cuerpo)),
        'DELETE' => http.delete(uri, headers: headers),
        _ => http.get(uri, headers: headers),
      };
      final r = await peticion.timeout(Duration(seconds: segundos));
      final data = jsonDecode(r.body) as Map<String, dynamic>;
      if (r.statusCode == 401) await AuthService.logout(); // token vencido
      return r.statusCode == 200 ? {...data, 'exito': true} : {'exito': false, 'mensaje': data['mensaje'] ?? 'Ocurrió un error'};
    } catch (_) {
      return {'exito': false, 'mensaje': 'No se pudo conectar al servidor'};
    }
  }

  /// Envía un mensaje. Sin conversacionId crea una conversación nueva. Devuelve {respuesta, conversacionId}
  static Future<Map<String, dynamic>> enviar(String mensaje, {Object? conversacionId}) =>
      _pedir('POST', '/chat', cuerpo: {'mensaje': mensaje, if (conversacionId != null) 'conversacionId': conversacionId}, segundos: 60);

  static Future<Map<String, dynamic>> conversaciones() => _pedir('GET', '/conversaciones');
  static Future<Map<String, dynamic>> historial(Object id) => _pedir('GET', '/chat/historial/$id');

  static Future<Map<String, dynamic>> renombrar(Object id, String titulo) => _pedir('PUT', '/conversaciones/$id', cuerpo: {'titulo': titulo});
  static Future<Map<String, dynamic>> eliminar(Object id) => _pedir('DELETE', '/conversaciones/$id');
}