import 'package:flutter/material.dart';
import '../core/app_colors.dart';
import 'app_card.dart';

class NextMatchCard extends StatelessWidget {
  final String title, subtitle;
  final VoidCallback? onTap;
  const NextMatchCard({super.key, required this.title, required this.subtitle, this.onTap});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return GestureDetector(
      onTap: onTap,
      child: AppCard(
        child: Row(children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: AppColors.primaryLight.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.event, color: AppColors.secondary),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: t.bodyMedium?.copyWith(color: AppColors.textWhite, fontWeight: FontWeight.bold)),
            Text(subtitle, style: t.bodySmall?.copyWith(color: AppColors.textGray)),
          ])),
          const Icon(Icons.chevron_right, color: AppColors.textGray),
        ]),
      ),
    );
  }
}