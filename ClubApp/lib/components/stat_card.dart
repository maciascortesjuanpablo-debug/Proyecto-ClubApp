import 'package:flutter/material.dart';
import '../core/app_colors.dart';

class StatCard extends StatelessWidget {
  final String value;
  final String label;
  final String subLabel;
  final Color color;

  const StatCard({super.key, required this.value, required this.label, required this.subLabel, required this.color});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: AppColors.bgCard, borderRadius: BorderRadius.circular(12)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(value, style: const TextStyle(fontSize: 26, color: AppColors.textWhite, fontWeight: FontWeight.bold)),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textGrayDark)),
          const SizedBox(height: 4),
          Text(subLabel, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w600)),
        ]),
      );
}