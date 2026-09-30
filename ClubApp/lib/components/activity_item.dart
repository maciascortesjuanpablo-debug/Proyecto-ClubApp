import 'package:flutter/material.dart';
import '../core/app_colors.dart';

class ActivityItem extends StatelessWidget {
  final String title;
  final String time;
  final IconData icon;
  final Color color;

  const ActivityItem({
    Key? key,
    required this.title,
    required this.time,
    required this.icon,
    required this.color,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: AppColors.bgCard,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: color.withOpacity(0.3), width: 1.5),
    ),
    padding: const EdgeInsets.all(16),
    child: Row(
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(child: Icon(icon, color: color, size: 26)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textWhite, fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              Text(time, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: color, fontWeight: FontWeight.w500)),
            ],
          ),
        ),
        Icon(Icons.arrow_forward_ios, color: color.withOpacity(0.5), size: 16),
      ],
    ),
  );
}