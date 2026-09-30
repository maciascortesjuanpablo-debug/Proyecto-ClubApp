import '../screens/estadisticas.dart';
import 'package:flutter/material.dart';
import '../core/app_colors.dart';
import '../components/nav_bar.dart';
import '../components/stat_card.dart';
import '../components/quick_action_button.dart';
import '../components/match_carrusel.dart';
import '../components/activity_item.dart';
import '../components/next_match.dart';
import '../components/stats_table.dart';
import 'calendar_page.dart';
import 'tournaments_page.dart';
import 'team_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _idx = 0;
  final _pc = PageController(viewportFraction: 0.9);
  final _tabla = [['1', 'FC Nocturnos', '8', '19'], ['2', 'Independiente', '8', '17'], ['3', 'Deportivo Cali', '8', '14'], ['4', 'Millonarios', '8', '12'], ['5', 'Aguila FC', '8', '9']];
  final _goleadores = [['1', 'Carlos R. · FC Nocturnos', '7'], ['2', 'Andrés M. · Independiente', '6'], ['3', 'Luis P. · Deportivo Cali', '5']];
  final List<Map<String, dynamic>> matches = [
    {'t1': 'FC Nocturnos', 'i1': 'NC', 't2': 'Aguila FC', 'i2': 'AF', 's1': 2, 's2': 1, 'l': 'LIGA BOGOTÁ', 'status': 'Activo'},
    {'t1': 'Deportivo Cali', 'i1': 'DC', 't2': 'Pereira', 'i2': 'PR', 's1': 1, 's2': 1, 'l': 'LIGA BOGOTÁ', 'status': 'Activo'},
    {'t1': 'Independiente', 'i1': 'IND', 't2': 'Santa Fe', 'i2': 'SF', 's1': 3, 's2': 0, 'l': 'LIGA BOGOTÁ', 'status': 'Finalizado'},
    {'t1': 'Millonarios', 'i1': 'MIL', 't2': 'Alianza', 'i2': 'ALI', 's1': 0, 's2': 2, 'l': 'LIGA BOGOTÁ', 'status': 'Activo'},
  ];

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.bgDark,
    body: SingleChildScrollView(
      child: Column(children: [
        _compactHeader(),
        _liveMatch(),
        _section('Acciones rápidas', _quickActions()),
        _sectionCarousel('Partidos Destacados', _matchCarousel()),
        _section('Próximo partido', const NextMatchCard(title: 'FC Nocturnos vs Millonarios', subtitle: 'Sáb 4 oct · 3:00 PM · Cancha El Salitre')),
        _section('Tabla de posiciones', StatsTable(headers: const ['#', 'Equipo', 'PJ', 'Pts'], rows: _tabla)),
        _section('Máximos goleadores', StatsTable(headers: const ['#', 'Jugador', 'Goles'], rows: _goleadores)),
        _section('Mis Estadísticas', _statsImproved()),
        _section('Actividad reciente', _activity()),
        const SizedBox(height: 100),
      ]),
    ),
    bottomNavigationBar: BottomNavBar(currentIndex: _idx, onTap: (i) => setState(() => _idx = i)),
  );

  Widget _compactHeader() => Container(
    decoration: BoxDecoration(color: AppColors.bgCard, borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24))),
    padding: EdgeInsets.fromLTRB(24, MediaQuery.of(context).padding.top + 16, 16, 16),
    child: Row(children: [
      CircleAvatar(radius: 22, backgroundColor: AppColors.primaryLight, child: const Text('J', style: TextStyle(color: AppColors.textWhite, fontWeight: FontWeight.bold, fontSize: 18))),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Bienvenido de vuelta,', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textGray)),
        Text('Juan Pablo', style: Theme.of(context).textTheme.titleMedium?.copyWith(color: AppColors.textWhite, fontWeight: FontWeight.bold)),
      ])),
      IconButton(icon: const Icon(Icons.search, color: AppColors.textGray), onPressed: () {}),
      IconButton(icon: const Icon(Icons.notifications_outlined, color: AppColors.textGray), onPressed: () {}),
    ]),
  );

  Widget _liveMatch() => Padding(
    padding: const EdgeInsets.all(24),
    child: Container(
      decoration: BoxDecoration(gradient: LinearGradient(colors: [AppColors.primaryLight, AppColors.primary]), borderRadius: BorderRadius.circular(16)),
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(color: AppColors.secondary, borderRadius: BorderRadius.circular(20)),
            child: const Text('Partido en curso', style: TextStyle(color: AppColors.bgDark, fontSize: 12, fontWeight: FontWeight.w600)),
          ),
          Text("67'", style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: AppColors.secondary, fontWeight: FontWeight.bold)),
        ]),
        const SizedBox(height: 12),
        Text('Liga Amateur Bogotá 2025', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textWhite, fontWeight: FontWeight.bold)),
        Text('Jornada 8 - fase de grupos', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textWhite.withOpacity(0.7))),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity, height: 40,
          child: ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.textWhite, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
            child: Text('Ver detalles', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.primary, fontWeight: FontWeight.bold)),
          ),
        ),
      ]),
    ),
  );

  Widget _section(String title, Widget child) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 24),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: Theme.of(context).textTheme.labelLarge?.copyWith(color: AppColors.textWhite, fontWeight: FontWeight.w600)),
      const SizedBox(height: 16),
      child,
      const SizedBox(height: 32),
    ]),
  );

  Widget _sectionCarousel(String title, Widget child) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Text(title, style: Theme.of(context).textTheme.labelLarge?.copyWith(color: AppColors.textWhite, fontWeight: FontWeight.w600)),
      ),
      const SizedBox(height: 16),
      child,
      const SizedBox(height: 32),
    ],
  );

  Widget _qa(IconData icon, String label, Widget page) => GestureDetector(
    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => page)),
    child: QuickActionButton(icon: icon, label: label),
  );

  Widget _quickActions() => Row(
    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
    children: [
      _qa(Icons.calendar_today, 'Calendario', const CalendarPage()),
      _qa(Icons.emoji_events, 'Torneos', const TournamentsPage()),
      _qa(Icons.group, 'Mi equipo', const TeamPage()),
      _qa(Icons.bar_chart, 'Estadísticas', const Estadisticas()),
    ],
  );

  Widget _matchCarousel() => SizedBox(
    height: 300,
    child: PageView(
      controller: _pc,
      children: matches.map((m) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: MatchCard(team1: m['t1'], team1Init: m['i1'], team2: m['t2'], team2Init: m['i2'], score1: m['s1'], score2: m['s2'], league: m['l'], status: m['status']),
      )).toList(),
    ),
  );

  Widget _statsImproved() => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Expanded(child: StatCard(value: '14', label: 'Partidos', subLabel: 'en esta sesión', icon: Icons.sports_soccer, color: AppColors.secondary)),
      const SizedBox(width: 12),
      Expanded(child: StatCard(value: '7', label: 'Goles', subLabel: 'Top 5', icon: Icons.sports_soccer_outlined, color: AppColors.success)),
      const SizedBox(width: 12),
      Expanded(child: StatCard(value: '3', label: 'Torneos', subLabel: 'Activos', icon: Icons.emoji_events, color: AppColors.primaryLight)),
    ],
  );

  Widget _activity() => Column(children: [
    ActivityItem(title: 'Carlos R. registró resultado Nocturnos 2-1', time: 'Hace 5m', icon: Icons.sports_soccer, color: AppColors.secondary),
    const SizedBox(height: 12),
    ActivityItem(title: 'Nuevo torneo disponible cerca de ti', time: 'Hace 1h', icon: Icons.emoji_events, color: AppColors.primaryLight),
    const SizedBox(height: 12),
    ActivityItem(title: 'Convocatoria enviada para el sábado', time: 'Hace 3h', icon: Icons.mail_outline, color: AppColors.success),
  ]);
}