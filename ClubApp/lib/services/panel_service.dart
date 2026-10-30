import '../models/models.dart';
import 'api_client.dart';
import 'resultado.dart';

/// Paneles de inicio por rol. Cada endpoint solo responde al rol que corresponde (el backend devuelve 403 a los demás).
class PanelService {
  static Future<Resultado<T>> _cargar<T>(String ruta, T Function(Map<String, dynamic>) convertir) async {
    final r = await ApiClient.pedir('GET', ruta);
    if (r['exito'] != true) return Resultado.fallo(r['mensaje'].toString());
    return Resultado.ok(convertir(r));
  }

  static Future<Resultado<PanelJugador>> jugador() => _cargar('/panel/jugador', PanelJugador.fromJson);
  static Future<Resultado<PanelEntrenador>> entrenador() => _cargar('/panel/entrenador', PanelEntrenador.fromJson);
  static Future<Resultado<PanelOrganizador>> organizador() => _cargar('/panel/organizador', PanelOrganizador.fromJson);
  static Future<Resultado<PanelArbitro>> arbitro() => _cargar('/panel/arbitro', PanelArbitro.fromJson);
}
