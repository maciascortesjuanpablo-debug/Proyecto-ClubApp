import 'package:flutter/material.dart';
import '../../components/tournament_chip.dart';
import '../../components/ui_kit.dart';
import '../../core/app_colors.dart';
import '../../core/roles.dart';
import '../../models/models.dart';
import '../../services/tournament_service.dart';
import '../login_page.dart';
import '../register_page_1.dart';
import '../torneo/torneo_page.dart';

/// Inicio para quien entra SIN iniciar sesión: presenta la app, invita a registrarse y deja ver los torneos públicos.
class InvitadoInicioPage extends StatefulWidget {
  final ValueChanged<int> onIrATab;
  const InvitadoInicioPage({super.key, required this.onIrATab});

  @override
  State<InvitadoInicioPage> createState() => _InvitadoInicioPageState();
}

class _InvitadoInicioPageState extends State<InvitadoInicioPage> {
  List<Torneo>? _torneos;
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    final json = await TournamentService.listar();
    if (!mounted) return;
    setState(() {
      _cargando = false;
      _torneos = json?.map(Torneo.fromJson).toList();
    });
  }

  void _login() => Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginPage()));
  void _registro() => Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterPage1()));

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: AppColors.bgDark,
        body: SafeArea(
          child: RefreshIndicator(
            onRefresh: _cargar,
            child: ListView(physics: const AlwaysScrollableScrollPhysics(), padding: const EdgeInsets.fromLTRB(20, 12, 20, 130), children: [
              _hero(),
              const SeccionTitulo('Torneos en juego', accion: 'Ver todos', onAccion: null),
              _torneosDestacados(),
              const SeccionTitulo('Una app para cada rol'),
              _roles(),
              const SeccionTitulo('Con tu cuenta puedes'),
              _beneficios(),
              const SizedBox(height: 22),
              _cierre(),
            ]),
          ),
        ),
      );

  Widget _hero() => Container(
        padding: const EdgeInsets.fromLTRB(22, 26, 22, 22),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [AppColors.blue, AppColors.primaryLight], begin: Alignment.topLeft, end: Alignment.bottomRight),
          borderRadius: BorderRadius.circular(26),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.18), borderRadius: BorderRadius.circular(16)),
            child: const Icon(Icons.sports_soccer, color: Colors.white, size: 32),
          ),
          const SizedBox(height: 18),
          const Text('Bienvenido a ClubApp', style: TextStyle(fontSize: 26, color: Colors.white, fontWeight: FontWeight.w800, height: 1.1)),
          const SizedBox(height: 8),
          Text('Organiza torneos, arma tu equipo y sigue cada partido del fútbol aficionado en un solo lugar.', style: TextStyle(fontSize: 14, color: Colors.white.withValues(alpha: 0.85), height: 1.35)),
          const SizedBox(height: 22),
          Row(children: [
            Expanded(child: FilledButton(onPressed: _login, style: FilledButton.styleFrom(backgroundColor: Colors.white, foregroundColor: AppColors.blue, padding: const EdgeInsets.symmetric(vertical: 14)), child: const Text('Iniciar sesión', style: TextStyle(fontWeight: FontWeight.bold)))),
            const SizedBox(width: 12),
            Expanded(child: OutlinedButton(onPressed: _registro, style: OutlinedButton.styleFrom(foregroundColor: Colors.white, side: const BorderSide(color: Colors.white70), padding: const EdgeInsets.symmetric(vertical: 14)), child: const Text('Crear cuenta', style: TextStyle(fontWeight: FontWeight.bold)))),
          ]),
        ]),
      );

  Widget _torneosDestacados() {
    if (_cargando) return const Padding(padding: EdgeInsets.all(30), child: Center(child: CircularProgressIndicator()));
    final lista = (_torneos ?? []).where((t) => !t.cerrado).take(3).toList();
    if (lista.isEmpty) return const TarjetaBase(child: EstadoVacio(icono: Icons.emoji_events_outlined, mensaje: 'Todavía no hay torneos para mostrar'));
    return Column(children: [
      for (final t in lista)
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: TarjetaBase(
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => TorneoPage(torneoId: t.id, nombre: t.nombre))),
            child: Row(children: [
              Container(width: 46, height: 46, decoration: BoxDecoration(color: AppColors.blue, borderRadius: BorderRadius.circular(13)), child: const Icon(Icons.emoji_events, color: Colors.white)),
              const SizedBox(width: 14),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(t.nombre, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 15, color: AppColors.textWhite, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 2),
                  Text([t.deporte, if (t.ciudad != null) t.ciudad!].where((e) => e.isNotEmpty).join(' · '), style: const TextStyle(fontSize: 12, color: AppColors.textGray)),
                ]),
              ),
              TournamentChip(t.estado, color: AppColors.success),
            ]),
          ),
        ),
      Align(alignment: Alignment.centerRight, child: TextButton(onPressed: () => widget.onIrATab(1), child: const Text('Ver todos los torneos', style: TextStyle(color: AppColors.secondary, fontWeight: FontWeight.w600)))),
    ]);
  }

  Widget _roles() {
    const items = [
      (RolApp.jugador, 'Sigue tus estadísticas, tu equipo y tus próximos partidos'),
      (RolApp.entrenador, 'Arma la plantilla, la alineación e inscribe a tu equipo'),
      (RolApp.organizador, 'Crea torneos, acepta equipos y programa los partidos'),
      (RolApp.arbitro, 'Consulta tus designaciones y registra los resultados'),
    ];
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 0.98,
      children: [
        for (final (rol, texto) in items)
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: AppColors.bgCard, borderRadius: BorderRadius.circular(18), border: Border.all(color: rol.color.withValues(alpha: 0.35))),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(padding: const EdgeInsets.all(9), decoration: BoxDecoration(color: rol.color.withValues(alpha: 0.18), borderRadius: BorderRadius.circular(12)), child: Icon(rol.icono, color: rol.color, size: 22)),
              const SizedBox(height: 10),
              Text(rol.nombre, style: const TextStyle(fontSize: 15, color: AppColors.textWhite, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Expanded(child: Text(texto, style: const TextStyle(fontSize: 12, color: AppColors.textGray, height: 1.3))),
            ]),
          ),
      ],
    );
  }

  Widget _beneficios() {
    const items = [
      (Icons.smart_toy_rounded, 'Scout AI', 'Un asistente que te recomienda jugadores y te ayuda a decidir.'),
      (Icons.leaderboard_rounded, 'Posiciones y resultados', 'Tablas, goleadores y marcadores al día de cada torneo.'),
      (Icons.calendar_month_rounded, 'Tu calendario', 'Tus partidos y designaciones, siempre a la mano.'),
    ];
    return Column(children: [
      for (final (icono, titulo, texto) in items)
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: TarjetaBase(
            child: Row(children: [
              Icon(icono, color: AppColors.secondary, size: 28),
              const SizedBox(width: 14),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(titulo, style: const TextStyle(color: AppColors.textWhite, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 2),
                  Text(texto, style: const TextStyle(fontSize: 12.5, color: AppColors.textGray)),
                ]),
              ),
            ]),
          ),
        ),
    ]);
  }

  Widget _cierre() => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: AppColors.bgCard, borderRadius: BorderRadius.circular(20)),
        child: Column(children: [
          const Text('¿Listo para entrar a la cancha?', textAlign: TextAlign.center, style: TextStyle(fontSize: 17, color: AppColors.textWhite, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          const Text('Crea tu cuenta gratis y elige tu rol.', textAlign: TextAlign.center, style: TextStyle(fontSize: 13, color: AppColors.textGray)),
          const SizedBox(height: 16),
          SizedBox(width: double.infinity, child: FilledButton(onPressed: _registro, style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)), child: const Text('Crear mi cuenta'))),
          TextButton(onPressed: _login, child: const Text('Ya tengo cuenta', style: TextStyle(color: AppColors.secondary))),
        ]),
      );
}