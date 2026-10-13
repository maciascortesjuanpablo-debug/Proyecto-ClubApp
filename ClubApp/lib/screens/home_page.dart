import 'package:flutter/material.dart';
import '../core/app_colors.dart';
import '../components/app_dialogs.dart';
import '../components/home/feature_highlights.dart';
import '../components/home/featured_matches.dart';
import '../components/home/guest_banner.dart';
import '../components/home/home_header.dart';
import '../components/home/home_stats.dart';
import '../components/home/live_match_banner.dart';
import '../components/home/load_error.dart';
import '../components/home/quick_actions.dart';
import '../components/home/recent_activity.dart';
import '../components/home/tournaments_preview.dart';
import '../services/auth_service.dart';
import '../services/home_services.dart';
import 'login_page.dart';
import 'register_page_1.dart';

class HomePage extends StatefulWidget {
  final void Function(int)? onIrATab;
  const HomePage({super.key, this.onIrATab});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool _cargando = true;
  Map<String, dynamic>? _data;

  @override
  void initState() {

    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    final eraLogueado = AuthService.isLoggedIn;
    var data = await HomeService.obtenerHome();
    // Token vencido: HomeService cierra la sesión y reintentamos como invitado
    if (data == null && eraLogueado && AuthService.isGuest) data = await HomeService.obtenerHome();
    if (!mounted) return;
    setState(() {
      _data = data;
      _cargando = false;
    });
  }

  void _tab(int i) => widget.onIrATab?.call(i);
  void _gate(VoidCallback accion) {
    if (requireAuth(context)) accion();
  }

  void _pronto(String seccion) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$seccion: próximamente')));

  void _push(Widget pagina) => Navigator.push(context, MaterialPageRoute(builder: (_) => pagina));

  void _reintentar() {
    setState(() => _cargando = true);
    _cargar();
  }

  @override

  Widget build(BuildContext context) {
    final d = _data;
    final guest = AuthService.isGuest;
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      body: RefreshIndicator(
        onRefresh: _cargar,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          children: [
            HomeHeader(
              logueado: AuthService.isLoggedIn,
              nombre: (d?['usuario']?['nombre'] ?? AuthService.usuario?['nombre'] ?? '').toString(),
              noLeidas: (d?['notificacionesNoLeidas'] ?? 0) as int,
              onLogin: () => _push(const LoginPage()),
              onBuscar: () => _pronto('Búsqueda'),
              onNotificaciones: () => _pronto('Notificaciones'),
            ),
            if (_cargando)
              const Padding(padding: EdgeInsets.all(60), child: Center(child: CircularProgressIndicator()))
            else if (d == null)
              LoadError(onRetry: _reintentar)
            else ...[
              if (guest) GuestBanner(onLogin: () => _push(const LoginPage()), onRegister: () => _push(const RegisterPage1())),
              LiveMatchBanner(partido: d['partidoEnVivo'] as Map<String, dynamic>?, onVerDetalles: () => _tab(1)),
              QuickActions(
                onCalendario: () => _tab(4),
                onTorneos: () => _tab(1),
                onEquipo: () => _gate(() => _tab(3)),
                onEstadisticas: () => _gate(() => _pronto('Estadísticas')),
              ),

              FeaturedMatches(partidos: (d['partidosDestacados'] as List?) ?? [], onVerMas: () => _tab(1)),
              HomeStats(logueado: !guest, stats: d['estadisticas'] as Map<String, dynamic>?, onLogin: () => _push(const LoginPage())),
              if (guest) FeatureHighlights(onTap: (_) => requireAuth(context)),
              RecentActivity(actividad: (d['actividadReciente'] as List?) ?? []),
              TournamentsPreview(torneos: (d['torneosActivos'] as List?) ?? [], onVerTodos: () => _tab(1)),
            ],
          ],
        ),
      ),
    );
  }
}