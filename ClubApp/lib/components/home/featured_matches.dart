import 'package:flutter/material.dart';
import '../../core/app_colors.dart';
import '../../services/home_services.dart';
import '../match_carrusel.dart';
import 'section_title.dart';

class FeaturedMatches extends StatelessWidget {
  final List partidos;
  final VoidCallback onVerMas;

  const FeaturedMatches({super.key, required this.partidos, required this.onVerMas});

  @override
  Widget build(BuildContext context) {
    // Una sola tarjeta ocupa todo el ancho; con varias, se asoma la siguiente
    final ancho = MediaQuery.sizeOf(context).width - (partidos.length > 1 ? 64 : 40);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: SectionTitle('Partidos Destacados', accion: 'Ver más', onAccion: onVerMas),
      ),
      if (partidos.isEmpty)
        const Padding(padding: EdgeInsets.symmetric(horizontal: 20), child: Text('Aún no hay partidos registrados', style: TextStyle(color: AppColors.textGray)))
      else
        SizedBox(
          height: 160,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: partidos.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (_, i) => SizedBox(width: ancho, child: _card(partidos[i])),

          ),
        ),
      const SizedBox(height: 28),
    ]);
  }

  Widget _card(dynamic raw) {
    final m = HomeService.partidoParaCard(raw as Map<String, dynamic>);
    return MatchCard(
      team1: m['t1'] as String,
      team1Init: m['i1'] as String,
      team2: m['t2'] as String,
      team2Init: m['i2'] as String,
      score1: m['s1'] as int,
      score2: m['s2'] as int,
      league: m['l'] as String,
      status: m['status'] as String,
      minuto: m['minuto'] as int,
    );
  }
}