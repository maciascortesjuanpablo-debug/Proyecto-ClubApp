import 'dart:async';
import 'package:flutter/material.dart';
import '../components/scout_burbuja.dart';
import '../models/models.dart';
import '../screens/notificaciones_page.dart';
import 'api_client.dart';
import 'auth_service.dart';
import 'resultado.dart';

/// Permite mostrar avisos (SnackBar) desde fuera de cualquier pantalla
final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

/// Notificaciones dentro de la app. Mientras hay sesión consulta el servidor cada 30 segundos (y al volver a abrir la app):
/// actualiza el contador de la campana y, si llegó algo nuevo, muestra un aviso emergente con acceso directo.
/// (No son notificaciones push del sistema: eso requiere Firebase Cloud Messaging.)
class NotificationService {
  /// Cantidad de notificaciones sin leer (la campana se actualiza sola)
  static final ValueNotifier<int> noLeidas = ValueNotifier(0);

  static Timer? _timer;
  static final Set<String> _vistas = {};
  static bool _primera = true;
  static bool _paginaAbierta = false;
  static final _ciclo = _CicloDeVida();

  /// Arranca o detiene la consulta según haya sesión. Se llama en cada cambio de pantalla.
  static void evaluarSesion() => WidgetsBinding.instance.addPostFrameCallback((_) {
        if (AuthService.isLoggedIn && _timer == null) {
          _iniciar();
        } else if (!AuthService.isLoggedIn && _timer != null) {
          _detener();
        }
      });

  static void _iniciar() {
    WidgetsBinding.instance.addObserver(_ciclo);
    _primera = true;
    _vistas.clear();
    consultar();
    _timer = Timer.periodic(const Duration(seconds: 30), (_) => consultar());
  }

  static void _detener() {
    WidgetsBinding.instance.removeObserver(_ciclo);
    _timer?.cancel();
    _timer = null;
    _vistas.clear();
    noLeidas.value = 0;
  }

  /// La pantalla de notificaciones avisa cuando se abre y se cierra para no mostrar avisos encima de sí misma
  static void paginaAbierta(bool abierta) => _paginaAbierta = abierta;

  /// Pide el resumen al servidor. Los avisos emergentes solo salen para lo que llega después de la primera consulta.
  static Future<void> consultar() async {
    if (!AuthService.isLoggedIn) return;
    final r = await ApiClient.pedir('GET', '/notificaciones/mias/resumen');
    if (r['exito'] != true || !AuthService.isLoggedIn) return;

    final total = toInt(r['total']);
    final ultimas = toLista(r['ultimas']).map(Notificacion.fromJson).toList();
    final nuevas = ultimas.where((n) => !_vistas.contains('${n.id}')).toList();
    if (!_primera && nuevas.isNotEmpty && !_paginaAbierta) _avisar(nuevas, total);
    _vistas.addAll(ultimas.map((n) => '${n.id}'));
    _primera = false;
    noLeidas.value = total;
  }

  static void _avisar(List<Notificacion> nuevas, int total) {
    final mensajero = scaffoldMessengerKey.currentState;
    if (mensajero == null) return;
    final texto = nuevas.length == 1 ? nuevas.first.titulo : 'Tienes ${nuevas.length} notificaciones nuevas';
    mensajero
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 7),
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 110),
        content: Row(children: [
          Icon(nuevas.first.icono, color: Colors.white, size: 20),
          const SizedBox(width: 12),
          Expanded(child: Text(texto, maxLines: 3, overflow: TextOverflow.ellipsis)),
        ]),
        action: SnackBarAction(label: 'Ver', onPressed: abrir),
      ));
  }

  /// Abre la pantalla de notificaciones desde cualquier lugar
  static void abrir() => navigatorKey.currentState?.push(MaterialPageRoute(builder: (_) => const NotificacionesPage()));

  // ---- Llamadas al servidor ----
  static Future<Resultado<List<Notificacion>>> listar() async {
    final r = await ApiClient.pedir('GET', '/notificaciones/mias?limite=100');
    return r['exito'] == true ? Resultado.ok(toLista(r['datos']).map(Notificacion.fromJson).toList()) : Resultado.fallo(r['mensaje'].toString());
  }

  static Future<bool> marcarLeida(Object id) async {
    final r = await ApiClient.pedir('PUT', '/notificaciones/$id/leida');
    if (r['exito'] == true && noLeidas.value > 0) noLeidas.value--;
    return r['exito'] == true;
  }

  static Future<bool> marcarTodas() async {
    final r = await ApiClient.pedir('PUT', '/notificaciones/leer-todas');
    if (r['exito'] == true) noLeidas.value = 0;
    return r['exito'] == true;
  }

  static Future<bool> eliminar(Object id) async {
    final r = await ApiClient.pedir('DELETE', '/notificaciones/$id');
    return r['exito'] == true;
  }
}

/// Al volver a la app desde segundo plano se consulta de inmediato
class _CicloDeVida with WidgetsBindingObserver {
  @override
  void didChangeAppLifecycleState(AppLifecycleState estado) {
    if (estado == AppLifecycleState.resumed) NotificationService.consultar();
  }
}