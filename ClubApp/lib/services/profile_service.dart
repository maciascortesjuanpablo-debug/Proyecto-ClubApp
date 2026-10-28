import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import '../config/api_config.dart';
import 'auth_service.dart';

/// Datos del usuario logueado. Todas las respuestas son {exito, mensaje, ...datos}
/// (las listas llegan en 'datos' y los errores traen además 'status').
class ProfileService {
  static const _timeout = Duration(seconds: 15);

  static Object? get _id => AuthService.usuario?['id'];

  static Future<Map<String, dynamic>> _procesar(http.Response r) async {
    if (r.statusCode == 401) await AuthService.logout(); // token vencido
    final data = jsonDecode(r.body);
    if (r.statusCode != 200 && r.statusCode != 201) {
      return {'exito': false, 'status': r.statusCode, 'mensaje': (data is Map ? data['mensaje'] : null) ?? 'Ocurrió un error'};
    }
    return data is Map<String, dynamic> ? {...data, 'exito': true} : {'exito': true, 'datos': data};
  }

  static Future<Map<String, dynamic>> _pedir(String metodo, String ruta, {Map<String, dynamic>? cuerpo}) async {
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}$ruta');
      final headers = {'Content-Type': 'application/json', 'Authorization': 'Bearer ${AuthService.token}'};
      final peticion = switch (metodo) {
        'POST' => http.post(uri, headers: headers, body: jsonEncode(cuerpo)),
        'PUT' => http.put(uri, headers: headers, body: jsonEncode(cuerpo)),
        'DELETE' => http.delete(uri, headers: headers),
        _ => http.get(uri, headers: headers),
      };

      return await _procesar(await peticion.timeout(_timeout));
    } catch (_) {
      return {'exito': false, 'mensaje': 'No se pudo conectar al servidor'};
    }
  }

  static Future<Map<String, dynamic>> usuario() => _pedir('GET', '/usuarios/$_id');

  /// Si todavía no tiene perfil de jugador responde exito:false con status 404
  static Future<Map<String, dynamic>> perfilJugador() => _pedir('GET', '/perfil-jugador/$_id');

  /// Una fila por partido jugado, en 'datos'
  static Future<Map<String, dynamic>> estadisticas() => _pedir('GET', '/estadisticas/jugador/$_id');

  static Future<Map<String, dynamic>> actualizarUsuario(Map<String, dynamic> cambios) => _pedir('PUT', '/usuarios/$_id', cuerpo: cambios);

  static Future<Map<String, dynamic>> guardarPerfilJugador(Map<String, dynamic> datos, {required bool existe}) =>
      existe ? _pedir('PUT', '/perfil-jugador/$_id', cuerpo: datos) : _pedir('POST', '/perfil-jugador', cuerpo: datos);

  static Future<Map<String, dynamic>> cambiarPassword({required String actual, required String nueva}) =>
      _pedir('POST', '/usuarios/cambiar-password', cuerpo: {'passwordActual': actual, 'nuevaPassword': nueva});

  /// Desactiva la cuenta (no se borran los datos)
  static Future<Map<String, dynamic>> eliminarCuenta() => _pedir('DELETE', '/usuarios/$_id');

  /// Sube la foto de perfil (jpg, png o webp, máx. 5 MB). Devuelve el perfil actualizado en 'perfil'
  static Future<Map<String, dynamic>> subirFoto(String ruta) async {
    try {
      final extension = ruta.split('.').last.toLowerCase();
      final peticion = http.MultipartRequest('PUT', Uri.parse('${ApiConfig.baseUrl}/perfil-jugador/$_id/foto'))
        ..headers['Authorization'] = 'Bearer ${AuthService.token}'
        ..files.add(await http.MultipartFile.fromPath('foto', ruta, contentType: MediaType('image', extension == 'jpg' ? 'jpeg' : extension)));

      return await _procesar(await http.Response.fromStream(await peticion.send().timeout(const Duration(seconds: 40))));
    } catch (_) {
      return {'exito': false, 'mensaje': 'No se pudo subir la foto'};
    }
  }
}