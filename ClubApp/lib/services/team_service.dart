import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import '../config/api_config.dart';
import '../models/models.dart';
import 'auth_service.dart';
import 'api_client.dart';
import 'resultado.dart';

/// Equipos: consulta (jugador), gestión (entrenador) y partidos
class TeamService {
  static List<Map<String, dynamic>> _lista(Map<String, dynamic> r) => toLista(r['datos']);

  /// Equipos del usuario según su rol (entrenador: los que dirige; jugador: donde juega)
  static Future<Resultado<List<Equipo>>> mios() async {
    final r = await ApiClient.pedir('GET', '/equipos/mios');
    return r['exito'] == true ? Resultado.ok(_lista(r).map(Equipo.fromJson).toList()) : Resultado.fallo(r['mensaje'].toString());
  }

  static Future<Resultado<List<JugadorPlantilla>>> plantilla(Object equipoId) async {
    final r = await ApiClient.pedir('GET', '/equipos/$equipoId/jugadores');
    return r['exito'] == true ? Resultado.ok(_lista(r).map(JugadorPlantilla.fromJson).toList()) : Resultado.fallo(r['mensaje'].toString());
  }

  static Future<Resultado<List<MiembroStaff>>> staff(Object equipoId) async {
    final r = await ApiClient.pedir('GET', '/equipos/$equipoId/staff');
    return r['exito'] == true ? Resultado.ok(_lista(r).map(MiembroStaff.fromJson).toList()) : Resultado.fallo(r['mensaje'].toString());
  }

  /// Partidos del equipo y su balance
  static Future<Resultado<({List<Partido> partidos, BalanceEquipo balance})>> partidos(Object equipoId) async {
    final r = await ApiClient.pedir('GET', '/equipos/$equipoId/partidos');
    if (r['exito'] != true) return Resultado.fallo(r['mensaje'].toString());
    return Resultado.ok((partidos: toLista(r['partidos']).map(Partido.fromJson).toList(), balance: BalanceEquipo.fromJson(toMap(r['balance']))));
  }

  // ---- Solo entrenador ----
  /// Crea el equipo con su ficha: nombre, eslogan, ciudad, formato, formación, cupo, color y descripción
  static Future<Map<String, dynamic>> crear(Map<String, dynamic> ficha) => ApiClient.pedir('POST', '/equipos', cuerpo: ficha);
  static Future<Map<String, dynamic>> actualizar(Object id, Map<String, dynamic> cambios) => ApiClient.pedir('PUT', '/equipos/$id', cuerpo: cambios);

  /// Sube el escudo del equipo (imagen JPG, PNG o WEBP)
  static Future<Map<String, dynamic>> subirEscudo(Object id, String ruta) async {
    try {
      final extension = ruta.split('.').last.toLowerCase();
      final peticion = http.MultipartRequest('PUT', Uri.parse('${ApiConfig.baseUrl}/equipos/$id/logo'))
        ..headers['Authorization'] = 'Bearer ${AuthService.token}'
        ..files.add(await http.MultipartFile.fromPath('logo', ruta, contentType: MediaType('image', extension == 'jpg' ? 'jpeg' : extension)));
      final r = await http.Response.fromStream(await peticion.send().timeout(const Duration(seconds: 40)));
      return {'exito': r.statusCode >= 200 && r.statusCode < 300, 'mensaje': r.statusCode >= 200 && r.statusCode < 300 ? 'Escudo actualizado' : 'No se pudo subir el escudo'};
    } catch (_) {
      return {'exito': false, 'mensaje': 'No se pudo subir el escudo'};
    }
  }

  /// Guarda la alineación del campo: formación y qué jugador ocupa cada casilla
  static Future<Map<String, dynamic>> guardarAlineacion(Object equipoId, String formacion, List<Map<String, dynamic>> titulares) =>
      ApiClient.pedir('PUT', '/equipos/$equipoId/alineacion', cuerpo: {'formacion': formacion, 'titulares': titulares});

  /// Ficha completa de un equipo
  static Future<Resultado<Equipo>> detalle(Object id) async {
    final r = await ApiClient.pedir('GET', '/equipos/$id');
    return r['exito'] == true ? Resultado.ok(Equipo.fromJson(r)) : Resultado.fallo(r['mensaje'].toString());
  }
  static Future<Map<String, dynamic>> eliminar(Object id) => ApiClient.pedir('DELETE', '/equipos/$id');

  static Future<Map<String, dynamic>> actualizarJugador(Object equipoId, Object usuarioId, Map<String, dynamic> cambios) => ApiClient.pedir('PUT', '/equipos/$equipoId/jugadores/$usuarioId', cuerpo: cambios);
  static Future<Map<String, dynamic>> quitarJugador(Object equipoId, Object usuarioId) => ApiClient.pedir('DELETE', '/equipos/$equipoId/jugadores/$usuarioId');

  static Future<Resultado<List<JugadorBuscado>>> buscarJugadores(String texto, Object equipoId) async {
    final r = await ApiClient.pedir('GET', '/equipos/buscar-jugadores?q=${Uri.encodeQueryComponent(texto)}&equipoId=$equipoId');
    return r['exito'] == true ? Resultado.ok(_lista(r).map(JugadorBuscado.fromJson).toList()) : Resultado.fallo(r['mensaje'].toString());
  }

  static Future<Map<String, dynamic>> invitar(Object equipoId, Object usuarioId, String? posicion) =>
      ApiClient.pedir('POST', '/inscripciones/invitaciones', cuerpo: {'equipo_id': equipoId, 'usuario_id': usuarioId, if (posicion != null && posicion.isNotEmpty) 'posicion_propuesta': posicion});

  static Future<Map<String, dynamic>> inscribirEnTorneo(Object equipoId, Object torneoId) => ApiClient.pedir('POST', '/inscripciones', cuerpo: {'equipo_id': equipoId, 'torneo_id': torneoId});

  // ---- Solo jugador ----
  static Future<Map<String, dynamic>> responderInvitacion(Object id, bool aceptar) => ApiClient.pedir('PUT', '/inscripciones/invitaciones/$id/responder', cuerpo: {'respuesta': aceptar ? 'Aceptada' : 'Rechazada'});
}