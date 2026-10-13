import 'package:flutter/material.dart';
import '../core/app_colors.dart';

/// Tarjeta de un partido destacado (liga, estado, escudos y marcador)
class MatchCard extends StatelessWidget {
  final String team1, team1Init, team2, team2Init, league, status;
  final int score1, score2, minuto;

  const MatchCard({
    super.key,
    required this.team1,
    required this.team1Init,
    required this.team2,
    required this.team2Init,
    required this.score1,
    required this.score2,
    required this.league,
    required this.status,
    this.minuto = 0,
  });

  @override
  Widget build(BuildContext context) {
    final vivo = status == 'En vivo';
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.bgCard, borderRadius: BorderRadius.circular(16)),
      child: Column(children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Expanded(
            child: Text(league,
                maxLines: 1,

                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: AppColors.primaryLight, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: vivo ? AppColors.blue : AppColors.bgCardLight, borderRadius: BorderRadius.circular(12)),
            child: Text(vivo ? "En vivo $minuto'" : status,
                style: const TextStyle(color: AppColors.textWhite, fontSize: 10.5, fontWeight: FontWeight.bold)),
          ),
        ]),
        const SizedBox(height: 14),
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(child: _team(team1, team1Init, AppColors.primary)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Column(children: [
              SizedBox(
                height: 52,
                child: Center(child: Text('$score1 : $score2', style: const TextStyle(fontSize: 30, color: AppColors.textWhite, fontWeight: FontWeight.bold))),
              ),
              const SizedBox(height: 8),
              const Text('VS', style: TextStyle(fontSize: 11, color: AppColors.textGray, fontWeight: FontWeight.bold)),
            ]),
          ),
          Expanded(child: _team(team2, team2Init, const Color(0xFF14532D))),
        ]),
      ]),
    );
  }

  Widget _team(String name, String init, Color color) => Column(children: [

        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          child: Center(child: Text(init, style: TextStyle(color: AppColors.textWhite.withValues(alpha: 0.7), fontSize: 14, fontWeight: FontWeight.bold))),
        ),
        const SizedBox(height: 8),
        Text(name, maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center, style: const TextStyle(fontSize: 11, color: AppColors.textWhite, fontWeight: FontWeight.bold)),
      ]);
}