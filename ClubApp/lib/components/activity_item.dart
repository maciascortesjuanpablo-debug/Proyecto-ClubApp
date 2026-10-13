import 'package:flutter/material.dart';
import '../core/app_colors.dart';

class ActivityItem extends StatelessWidget {
  final String title;
  final String time;
  final bool nuevo; // punto verde: notificación personal

  const ActivityItem({super.key, required this.title, required this.time, this.nuevo = false});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(color: AppColors.bgCard, borderRadius: BorderRadius.circular(20)),
        child: Row(children: [
          if (nuevo) ...[
            Container(width: 6, height: 6, decoration: const BoxDecoration(color: AppColors.success, shape: BoxShape.circle)),
            const SizedBox(width: 10),
          ],
          Expanded(child: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, color: AppColors.textWhite, fontWeight: FontWeight.w600))),
          const SizedBox(width: 8),
          Text(time, style: const TextStyle(fontSize: 10, color: AppColors.textGray)),
        ]),
      );
}