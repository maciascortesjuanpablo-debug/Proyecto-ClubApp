import 'package:flutter/material.dart';
import '../core/app_colors.dart';

class StatCard extends StatelessWidget {
  final String value;
  final String label;
  final String subLabel;
  final IconData icon;
  final Color color;

  const StatCard({
    Key? key,
    required this.value,
    required this.label,
    required this.subLabel,
    required this.icon,
    required this.color,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [color.withOpacity(0.9), color.withOpacity(0.5)],
      ),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: color, width: 2),
    ),
    padding: const EdgeInsets.all(24),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(color: color.withOpacity(0.25), borderRadius: BorderRadius.circular(14)),
          child: Center(child: Icon(icon, color: color, size: 32)),
        ),
        const SizedBox(height: 16),
        Text(value, style: Theme.of(context).textTheme.displaySmall?.copyWith(color: AppColors.textWhite, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Text(label, style: Theme.of(context).textTheme.labelMedium?.copyWith(color: AppColors.textWhite, fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        Text(subLabel, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppColors.textWhite.withOpacity(0.7), fontSize: 11)),
      ],
    ),
  );
}