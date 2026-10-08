import 'package:flutter/material.dart';
import '../core/app_colors.dart';
import '../components/nav_bar.dart';
import '../components/stat_card.dart';
import '../components/quick_action_button.dart';
import '../components/match_carrusel.dart';
import '../components/activity_item.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _idx = 0;
  final matches = [
    {'t1': 'FC Nocturnos', 'i1': 'NC', 't2': 'Aguila FC', 'i2': 'AF', 's1': 2, 's2': 1, 'l': 'LIGA BOGOTÁ', 'status': 'Activo'},
    {'t1': 'Deportivo Cali', 'i1': 'DC', 't2': 'Pereira', 'i2': 'PR', 's1': 1, 's2': 1, 'l': 'LIGA BOGOTÁ', 'status': 'Activo'},
    {'t1': 'Independiente', 'i1': 'IND', 't2': 'Santa Fe', 'i2': 'SF', 's1': 3, 's2': 0, 'l': 'LIGA BOGOTÁ', 'status': 'Finalizado'},
  ];

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.bgDark,
    body: SingleChildScrollView(
      child: Column(children: [
        _header(),
        _liveMatch(),
        _actions(),
        _matchesSection(),
        _statsSection(),
        const SizedBox(height: 100),
      ]),
    ),
    bottomNavigationBar: BottomNavBar(currentIndex: _idx, onTap: (i) => setState(() => _idx = i)),
  );

  Widget _header() => Container(
    color: AppColors.bgCard,
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
    child: SafeArea(
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Bienvenido', style: TextStyle(fontSize: 14, color: AppColors.textGray, fontWeight: FontWeight.w500)),
          const SizedBox(height: 4),
          const Text('Juan Pablo', style: TextStyle(fontSize: 22, color: AppColors.textWhite, fontWeight: FontWeight.bold)),
        ]),
        Row(children: [
          IconButton(icon: const Icon(Icons.search, color: AppColors.textGray, size: 20), onPressed: () {}, constraints: const BoxConstraints()),
          const SizedBox(width: 8),
          IconButton(icon: const Icon(Icons.notifications_outlined, color: AppColors.textGray, size: 20), onPressed: () {}, constraints: const BoxConstraints()),
        ]),
      ]),
    ),
  );

  Widget _liveMatch() => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
    child: Container(
      decoration: BoxDecoration(gradient: LinearGradient(colors: [AppColors.primaryLight, AppColors.primary]), borderRadius: BorderRadius.circular(16)),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: AppColors.secondary.withOpacity(0.9), borderRadius: BorderRadius.circular(16)),
            child: const Text('EN VIVO', style: TextStyle(color: AppColors.bgDark, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
          ),
          const Text("67'", style: TextStyle(color: AppColors.secondary, fontSize: 18, fontWeight: FontWeight.bold)),
        ]),
        const SizedBox(height: 14),
        const Text('Liga Amateur Bogotá', style: TextStyle(fontSize: 14, color: AppColors.textWhite, fontWeight: FontWeight.bold)),
        const SizedBox(height: 2),
        Text('Jornada 8', style: TextStyle(fontSize: 12, color: AppColors.textWhite.withOpacity(0.7))),
        const SizedBox(height: 14),
        SizedBox(
          width: double.infinity,
          height: 36,
          child: ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.textWhite, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
            child: const Text('Ver detalles', style: TextStyle(color: AppColors.primary, fontSize: 13, fontWeight: FontWeight.w600)),
          ),
        ),
      ]),
    ),
  );

  Widget _actions() => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
      QuickActionButton(icon: Icons.calendar_today, label: 'Calendario'),
      QuickActionButton(icon: Icons.emoji_events, label: 'Torneos'),
      QuickActionButton(icon: Icons.group, label: 'Mi equipo'),
      QuickActionButton(icon: Icons.bar_chart, label: 'Estadísticas'),
    ]),
  );

  Widget _matchesSection() => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        const Text('Partidos destacados', style: TextStyle(fontSize: 16, color: AppColors.textWhite, fontWeight: FontWeight.w600)),
        Text('Ver más', style: TextStyle(fontSize: 12, color: AppColors.secondary, fontWeight: FontWeight.w600)),
      ]),
    ),
    SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          children: matches.map((m) => Padding(
            padding: const EdgeInsets.only(right: 16),
            child: SizedBox(
              width: 280,
              child: MatchCard(
                team1: m['t1'] as String, team1Init: m['i1'] as String,
                team2: m['t2'] as String, team2Init: m['i2'] as String,
                score1: m['s1'] as int, score2: m['s2'] as int,
                league: m['l'] as String, status: m['status'] as String,
              ),
            ),
          )).toList(),
        ),
      ),
    const SizedBox(height: 24),
  ]);

  Widget _statsSection() => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 20),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Mis estadísticas', style: TextStyle(fontSize: 16, color: AppColors.textWhite, fontWeight: FontWeight.w600)),
      const SizedBox(height: 14),
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(child: StatCard(value: '14', label: 'Partidos', subLabel: 'en esta sesión', icon: Icons.sports_soccer, color: AppColors.secondary)),
          const SizedBox(width: 10),
          Expanded(child: StatCard(value: '7', label: 'Goles', subLabel: 'Top 5', icon: Icons.sports_soccer_outlined, color: AppColors.success)),
          const SizedBox(width: 10),
          Expanded(child: StatCard(value: '3', label: 'Torneos', subLabel: 'Activos', icon: Icons.emoji_events, color: AppColors.primaryLight)),
        ],
      ),
      const SizedBox(height: 24),
      const Text('Actividad reciente', style: TextStyle(fontSize: 16, color: AppColors.textWhite, fontWeight: FontWeight.w600)),
      const SizedBox(height: 14),
      ActivityItem(title: 'Carlos R. registró resultado Nocturnos 2-1', time: 'Hace 5m', icon: Icons.sports_soccer, color: AppColors.secondary),
      const SizedBox(height: 10),
      ActivityItem(title: 'Nuevo torneo disponible', time: 'Hace 1h', icon: Icons.emoji_events, color: AppColors.primaryLight),
      const SizedBox(height: 10),
      ActivityItem(title: 'Convocatoria enviada para el sábado', time: 'Hace 3h', icon: Icons.mail_outline, color: AppColors.success),
    ]),
  );
}