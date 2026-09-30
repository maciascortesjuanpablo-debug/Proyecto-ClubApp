import 'package:flutter/material.dart';
import '../core/app_colors.dart';

class MatchCard extends StatelessWidget {
  final String team1, team1Init, team2, team2Init, league, status;
  final int score1, score2;

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
  });

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    Widget score(int s, Color c) => Text('$s', style: t.headlineMedium?.copyWith(color: c, fontWeight: FontWeight.bold));

    return Container(
      height: 300,
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primaryLight, width: 2),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(league, style: t.labelMedium?.copyWith(color: AppColors.secondary, fontWeight: FontWeight.w600)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(color: AppColors.success, borderRadius: BorderRadius.circular(6)),
            child: Text(status, style: const TextStyle(color: AppColors.bgDark, fontSize: 12, fontWeight: FontWeight.w600)),
          ),
        ]),
        const SizedBox(height: 16),
        Expanded(
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
            _team(t, team1, team1Init),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                score(score1, AppColors.secondary),
                Text('vs', style: t.bodyMedium?.copyWith(color: AppColors.textGray, fontWeight: FontWeight.w600)),
                score(score2, AppColors.success),
              ]),
            ),
            _team(t, team2, team2Init),
          ]),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          height: 44,
          child: ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryLight, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            child: Text('Ver detalles', style: t.bodyMedium?.copyWith(color: AppColors.textWhite, fontWeight: FontWeight.w600)),
          ),
        ),
      ]),
    );
  }

  Widget _team(TextTheme t, String name, String init) => Column(mainAxisAlignment: MainAxisAlignment.center, children: [
    Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(12)),
      child: Center(child: Text(init, style: const TextStyle(color: AppColors.textWhite, fontWeight: FontWeight.bold, fontSize: 18))),
    ),
    const SizedBox(height: 8),
    SizedBox(
      width: 80,
      child: Text(name, style: t.bodySmall?.copyWith(color: AppColors.textGray, fontWeight: FontWeight.w600), textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis),
    ),
  ]);
}