import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/app_constants.dart';
import 'auth_service.dart';

class HomeService {
  /// Con sesión trae los datos privados; como invitado, los públicos.
  static Future<Map<String, dynamic>?> obtenerHome() async {
    try {
      final logueado = AuthService.isLoggedIn;
      final response = await http.get(
        Uri.parse('${AppConfig.apiUrl}/home${logueado ? '' : '/publico'}'),
        headers: {
          'Content-Type': 'application/json',
          if (logueado) 'Authorization': 'Bearer ${AuthService.token}',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
      if (response.statusCode == 401) {
        await AuthService.logout(); // token vencido
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  static String iniciales(String nombre) {
    final partes = nombre.trim().split(RegExp(r'\s+')).where((e) => e.isNotEmpty).toList();
    if (partes.isEmpty) return '?';
    if (partes.length == 1) {
      final p = partes[0];
      return (p.length >= 2 ? p.substring(0, 2) : p).toUpperCase();
    }
    return (partes[0][0] + partes[1][0]).toUpperCase();
  }

  /// Convierte un partido del backend al formato que ya usa tu MatchCard
  static Map<String, dynamic> partidoParaCard(Map<String, dynamic> p) {
    final local = (p['equipo_local']?['nombre'] ?? 'Local').toString();
    final visitante = (p['equipo_visitante']?['nombre'] ?? 'Visitante').toString();
    final estado = (p['estado'] ?? 'Programado').toString();
    return {
      't1': local,
      'i1': iniciales(local),
      't2': visitante,
      'i2': iniciales(visitante),
      's1': p['resultado_local'] ?? 0,
      's2': p['resultado_visitante'] ?? 0,
      'l': (p['torneos']?['nombre'] ?? '').toString().toUpperCase(),
      'status': estado,
      'minuto': minutoAproximado(p),
    };
  }

  /// La BD no guarda el minuto: se calcula desde la hora de inicio
  static int minutoAproximado(Map<String, dynamic> p) {
    try {
      final inicio = DateTime.parse('${p['fecha']} ${p['hora']}');
      return DateTime.now().difference(inicio).inMinutes.clamp(0, 120).toInt();
    } catch (_) {
      return 0;
    }
  }

  static String hace(String? iso) {
    final d = DateTime.tryParse(iso ?? '')?.toLocal();
    if (d == null) return '';
    final diff = DateTime.now().difference(d);
    if (diff.inMinutes < 1) return 'Ahora';
    if (diff.inMinutes < 60) return 'Hace ${diff.inMinutes}m';
    if (diff.inHours < 24) return 'Hace ${diff.inHours}h';
    return 'Hace ${diff.inDays}d';
  }
}