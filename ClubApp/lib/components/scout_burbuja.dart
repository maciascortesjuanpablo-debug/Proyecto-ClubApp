import 'package:flutter/material.dart';
import '../core/app_colors.dart';
import '../screens/scout_page.dart';
import '../services/auth_service.dart';
import '../services/notification_service.dart';

/// Clave del navegador principal: la burbuja vive por encima del Navigator y necesita abrir pantallas desde fuera de él.
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

/// Avisa cada vez que cambia la pantalla: la burbuja vuelve a evaluar si hay sesión y,
/// con sesión, las notificaciones empiezan a consultarse (sin sesión se detienen).
class ScoutObserver extends NavigatorObserver {
  void _cambio() {
    ScoutBurbuja.refrescar();
    NotificationService.evaluarSesion();
  }

  @override
  void didPush(Route route, Route? previousRoute) => _cambio();
  @override
  void didPop(Route route, Route? previousRoute) => _cambio();
  @override
  void didRemove(Route route, Route? previousRoute) => _cambio();
  @override
  void didReplace({Route? newRoute, Route? oldRoute}) => _cambio();
}

/// Burbuja de chat con Scout AI, visible en todas las pantallas para quien tiene sesión (de cualquier rol).
/// Los invitados no la ven. Se puede arrastrar para que no tape nada; al tocarla abre el chat.
class ScoutBurbuja extends StatelessWidget {
  const ScoutBurbuja({super.key});

  static final ValueNotifier<int> _cambios = ValueNotifier(0);
  static int _ocultadores = 0; // pantallas que piden esconderla (el propio chat)
  static double _izquierda = 14;
  static double _abajo = 112;

  /// Vuelve a evaluar la visibilidad después del frame actual (los avisos pueden llegar en plena construcción)
  static void refrescar() => WidgetsBinding.instance.addPostFrameCallback((_) => _cambios.value++);

  static void ocultar() {
    _ocultadores++;
    refrescar();
  }

  static void mostrar() {
    if (_ocultadores > 0) _ocultadores--;
    refrescar();
  }

  void _abrir() {
    final nav = navigatorKey.currentState;
    if (nav == null) return;
    nav.push(MaterialPageRoute(builder: (_) => const ScoutPage()));
  }

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<int>(
        valueListenable: _cambios,
        builder: (context, _, __) {
          final teclado = MediaQuery.of(context).viewInsets.bottom > 0;
          if (AuthService.isGuest || _ocultadores > 0 || teclado) return const SizedBox.shrink();
          return _Arrastrable(onTap: _abrir);
        },
      );
}

class _Arrastrable extends StatefulWidget {
  final VoidCallback onTap;
  const _Arrastrable({required this.onTap});

  @override
  State<_Arrastrable> createState() => _ArrastrableState();
}

class _ArrastrableState extends State<_Arrastrable> {
  static const _tam = 56.0;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final seguro = MediaQuery.of(context).padding;
    final left = ScoutBurbuja._izquierda.clamp(0.0, size.width - _tam);
    final bottom = ScoutBurbuja._abajo.clamp(seguro.bottom, size.height - _tam - seguro.top);
    return Positioned(
      left: left,
      bottom: bottom,
      child: GestureDetector(
        onPanUpdate: (d) => setState(() {
          ScoutBurbuja._izquierda = (left + d.delta.dx).clamp(0.0, size.width - _tam);
          ScoutBurbuja._abajo = (bottom - d.delta.dy).clamp(seguro.bottom, size.height - _tam - seguro.top);
        }),
        child: Material(
          color: Colors.transparent,
          shape: const CircleBorder(),
          elevation: 8,
          shadowColor: Colors.black54,
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: widget.onTap,
            child: Container(
              width: _tam,
              height: _tam,
              decoration: const BoxDecoration(shape: BoxShape.circle, gradient: LinearGradient(colors: [AppColors.secondary, AppColors.primaryLight], begin: Alignment.topLeft, end: Alignment.bottomRight)),
              child: const Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(Icons.smart_toy_rounded, color: AppColors.bgDark, size: 25),
                Text('IA', style: TextStyle(fontSize: 10, color: AppColors.bgDark, fontWeight: FontWeight.w900, height: 1)),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}