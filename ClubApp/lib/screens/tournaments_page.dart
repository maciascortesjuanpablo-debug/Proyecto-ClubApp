import 'package:flutter/material.dart';
import '../core/app_colors.dart';
import '../components/nav_bar.dart';
import '../components/tournament_card.dart';
import '../services/auth_service.dart';

class TournamentsPage extends StatefulWidget {
  const TournamentsPage({Key? key}) : super(key: key);
  @override
  State<TournamentsPage> createState() => _TournamentsPageState();
}

class _TournamentsPageState extends State<TournamentsPage> {
  int _idx = 1;
  String _filter = 'Todos';
  final _searchController = TextEditingController();

  final List<Map> tournaments = [
    {'name': 'Copa bogotá 2025', 'sport': 'Futbol 11', 'format': 'liga', 'status': 'Activo', 'teams': 12, 'max': 16, 'date': '5/15', 'active': true},
    {'name': 'Torneo Relampago', 'sport': 'Futbol 5', 'format': 'Eliminación', 'status': 'Inscripciomnes', 'teams': 6, 'max': 8, 'date': 'Mar 30', 'active': false},
    {'name': 'Liga Nocturna', 'sport': 'Futbol 11', 'format': 'liga', 'status': 'Activo', 'teams': 10, 'max': 14, 'date': '6/10', 'active': true},
  ];

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.bgDark,
    body: SingleChildScrollView(
      child: Column(
        children: [
          _header(),
          _searchBar(),
          _filters(),
          _tournamentsSection(),
          const SizedBox(height: 100),
        ],
      ),
    ),
    bottomNavigationBar: BottomNavBar(currentIndex: _idx, onTap: (i) => setState(() => _idx = i)),
  );

  Widget _header() => Padding(
    padding: const EdgeInsets.all(24),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Torneos', style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: AppColors.textWhite, fontWeight: FontWeight.bold)),
            Text('Encuentra o crea un torneo', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textGray)),
          ],
        ),
        GestureDetector(
          onTap: () {
            AuthService.requireAuth(context);
            if (AuthService.isLoggedIn) {
              // Navegar a CreateTournament
            }
          },
          child: Container(
            width: 50, height: 50,
            decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(12)),
            child: const Center(child: Icon(Icons.add, color: AppColors.textWhite, size: 28)),
          ),
        ),
      ],
    ),
  );

  Widget _searchBar() => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 24),
    child: TextField(
      controller: _searchController,
      decoration: InputDecoration(
        hintText: 'Buscar torneo o ciudad....',
        hintStyle: const TextStyle(color: AppColors.textGrayDark),
        prefixIcon: const Icon(Icons.search, color: AppColors.textGray),
        filled: true,
        fillColor: AppColors.bgCard,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      ),
      style: const TextStyle(color: AppColors.textWhite),
    ),
  );

  Widget _filters() => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
    child: Row(
      children: ['Todos', 'Activos', 'Próximos', 'Mis torneos'].map((f) => GestureDetector(
        onTap: () => setState(() => _filter = f),
        child: Container(
          margin: const EdgeInsets.only(right: 8),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: _filter == f ? AppColors.primaryLight : AppColors.bgCard,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(f, style: TextStyle(color: AppColors.textWhite, fontSize: 12, fontWeight: FontWeight.w600)),
        ),
      )).toList(),
    ),
  );

  Widget _tournamentsSection() => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 24),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('ACTIVOS CERCA DE TI', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppColors.textGray, fontWeight: FontWeight.w600)),
        const SizedBox(height: 12),
        ...tournaments.map((t) => Column(
          children: [
            TournamentCard(
              name: t['name'],
              sport: t['sport'],
              format: t['format'],
              status: t['status'],
              teams: t['teams'],
              maxTeams: t['max'],
              startDate: t['date'],
              isActive: t['active'],
              onTap: () {
                AuthService.requireAuth(context);
                if (AuthService.isLoggedIn) {
                  // Navegar a detalles
                }
              },
            ),
            const SizedBox(height: 12),
          ],
        )).toList(),
      ],
    ),
  );
}