import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import 'auth_service.dart';

class TournamentService {
  static const _timeout = Duration(seconds: 12);

  static Uri _uri(String ruta) => Uri.parse('${ApiConfig.baseUrl}$ruta');

  /// Lista de objetos JSON (torneos, deportes, formatos) o null si falla la petición
  static Future<List<Map<String, dynamic>>?> _lista(String ruta) async {
    try {
      final r = await http.get(_uri(ruta)).timeout(_timeout);
      if (r.statusCode != 200) return null;
      return (jsonDecode(r.body) as List).cast<Map<String, dynamic>>();
    } catch (_) {
      return null;
    }
  }

  static Future<List<Map<String, dynamic>>?> listar() => _lista('/torneos');
  static Future<List<Map<String, dynamic>>?> deportes() => _lista('/catalogo/deportes');
  static Future<List<Map<String, dynamic>>?> formatos() => _lista('/catalogo/formatos');

  /// Solo organizadores y admins. Devuelve {exito, mensaje, torneo}
  static Future<Map<String, dynamic>> crear({
    required String nombre,
    required Object deporteId,
    required Object formatoId,
    required int maxEquipos,
    String? ciudad,

    int? jornadaTotal,
  }) async {
    try {
      final r = await http
          .post(
            _uri('/torneos'),
            headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer ${AuthService.token}'},
            body: jsonEncode({
              'nombre': nombre,
              'deporte_id': deporteId,
              'formato_id': formatoId,
              'max_equipos': maxEquipos,
              if (ciudad != null) 'ciudad': ciudad,
              if (jornadaTotal != null) 'jornada_total': jornadaTotal,
            }),
          )
          .timeout(_timeout);
      final data = jsonDecode(r.body) as Map<String, dynamic>;
      if (r.statusCode == 401) await AuthService.logout(); // token vencido
      return r.statusCode == 201 ? {...data, 'exito': true} : {'exito': false, 'mensaje': data['mensaje'] ?? 'No se pudo crear el torneo'};
    } catch (_) {
      return {'exito': false, 'mensaje': 'No se pudo conectar al servidor'};
    }
  }
}