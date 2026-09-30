import 'package:flutter/material.dart';
import '../core/app_colors.dart';

class TournamentCard extends StatelessWidget {
  final String name;
  final String sport;
  final String format;
  final String status;
  final int teams;
  final int maxTeams;
  final String startDate;
  final bool isActive;
  final VoidCallback? onTap;

  const TournamentCard({
    Key? key,
    required this.name,
    required this.sport,
    required this.format,
    required this.status,
    required this.teams,
    required this.maxTeams,
    required this.startDate,
    required this.isActive,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      decoration: BoxDecoration(
        color: isActive ? AppColors.primaryLight : AppColors.bgCard,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(name, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textWhite, fontWeight: FontWeight.bold)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: status == 'Activo' ? AppColors.success : AppColors.secondary.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(status, style: const TextStyle(color: AppColors.bgDark, fontSize: 10, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(sport, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppColors.textGray)),
          const SizedBox(height: 8),
          Text('Equipos: $teams/$maxTeams  Formato: $format  Jornada: $startDate',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppColors.textGrayDark, fontSize: 11)),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: teams / maxTeams,
              minHeight: 4,
              backgroundColor: AppColors.bgCard,
              valueColor: AlwaysStoppedAnimation(isActive ? AppColors.secondary : AppColors.success),
            ),
          ),
        ],
      ),
    ),
  );
}