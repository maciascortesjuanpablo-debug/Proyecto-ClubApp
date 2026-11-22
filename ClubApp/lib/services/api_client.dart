import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart'; 
import 'auth_service.dart';

/// Petición autenticada genérica al backend.
/// Devuelve {exito, status (si falló), mensaje, ...datos}; las respuestas que son listas llegan en 'datos'.
class ApiClient {
  static Future<Map<String, dynamic>> pedir(String metodo, String ruta, {Map<String, dynamic>? cuerpo}) async {
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}$ruta');
      final headers = {'Content-Type': 'application/json', 'Authorization': 'Bearer ${AuthService.token}'};
      final body = jsonEncode(cuerpo ?? {}); // sin cuerpo se envía {} (Express rechaza el literal "null")
      final peticion = switch (metodo) {
        'POST' => http.post(uri, headers: headers, body: body),
        'PUT' => http.put(uri, headers: headers, body: body),
        'DELETE' => http.delete(uri, headers: headers),
        _ => http.get(uri, headers: headers),
      };
      final r = await peticion.timeout(const Duration(seconds: 20));
      if (r.statusCode == 401) await AuthService.logout(); // token vencido
      final data = jsonDecode(r.body);
      if (r.statusCode < 200 || r.statusCode > 299) {
        if (kDebugMode) debugPrint('API $metodo $ruta → ${r.statusCode}: ${r.body}'); // nunca en release
        return {'exito': false, 'status': r.statusCode, 'mensaje': (data is Map ? data['mensaje'] : null) ?? 'Ocurrió un error'};
      }
      return data is Map<String, dynamic> ? {...data, 'exito': true} : {'exito': true, 'datos': data};
    } catch (e) {
      if (kDebugMode) debugPrint('API $metodo $ruta falló: $e');
      return {'exito': false, 'mensaje': 'No se pudo conectar al servidor'};
    }
  }
}