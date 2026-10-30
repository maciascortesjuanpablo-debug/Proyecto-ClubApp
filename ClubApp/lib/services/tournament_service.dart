import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/models.dart';
import 'api_client.dart';
import 'auth_service.dart';
import 'resultado.dart';

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

  // ---- Detalle de un torneo (público) ----
  static Future<Resultado<ResumenTorneo>> resumen(Object id) async {
    final r = await ApiClient.pedir('GET', '/torneos/$id/resumen');
    return r['exito'] == true ? Resultado.ok(ResumenTorneo.fromJson(r)) : Resultado.fallo(r['mensaje'].toString());
  }

  static Future<Resultado<List<FilaPosicion>>> tabla(Object id) async {
    final r = await ApiClient.pedir('GET', '/inscripciones/tabla-posiciones/$id');
    return r['exito'] == true ? Resultado.ok(toLista(r['datos']).map(FilaPosicion.fromJson).toList()) : Resultado.fallo(r['mensaje'].toString());
  }

  /// Todos los eventos del torneo (partidos y otros), de más antiguo a más reciente
  static Future<Resultado<List<Partido>>> eventos(Object id) async {
    final r = await ApiClient.pedir('GET', '/calendario/eventos/torneo/$id');
    if (r['exito'] != true) return Resultado.fallo(r['mensaje'].toString());
    final lista = toLista(r['datos']).map(Partido.fromJson).toList();
    lista.sort((a, b) => '${a.diaIso} ${a.hora}'.compareTo('${b.diaIso} ${b.hora}'));
    return Resultado.ok(lista);
  }

  static Future<Resultado<List<Inscripcion>>> inscripciones(Object id) async {
    final r = await ApiClient.pedir('GET', '/inscripciones/torneo/$id');
    return r['exito'] == true ? Resultado.ok(toLista(r['datos']).map(Inscripcion.fromJson).toList()) : Resultado.fallo(r['mensaje'].toString());
  }

  /// Organizador del torneo o admin: aceptar o rechazar una inscripción
  static Future<Map<String, dynamic>> resolverInscripcion(Object id, String estado) => ApiClient.pedir('PUT', '/inscripciones/$id/estado', cuerpo: {'estado': estado});

  /// Torneos de gestión: los propios del organizador (o todos si es admin)
  static Future<Resultado<List<Torneo>>> gestionables() async {
    final admin = AuthService.usuario?['rol_id'] == 6;
    final r = await ApiClient.pedir('GET', admin ? '/torneos' : '/torneos/organizador/${AuthService.usuario?['id']}');
    return r['exito'] == true ? Resultado.ok(toLista(r['datos']).map(Torneo.fromJson).toList()) : Resultado.fallo(r['mensaje'].toString());
  }

  static Future<Map<String, dynamic>> cambiarEstado(Object id, String estado) => ApiClient.pedir('PUT', '/torneos/$id', cuerpo: {'estado': estado});
}