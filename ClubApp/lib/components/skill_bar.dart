import 'package:flutter/material.dart';
import '../core/app_colors.dart';

class SkillBar extends StatelessWidget {
  final String skillName;
  final double value; // 0.0 to 1.0
  final int percentage;
  final Color barColor;

  const SkillBar({
    Key? key,
    required this.skillName,
    required this.value,
    required this.percentage,
    this.barColor = AppColors.secondary,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              skillName,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textGray,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              '$percentage',
              style: TextStyle(
                fontSize: 12,
                color: barColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: value,
            minHeight: 6,
            backgroundColor: AppColors.bgCard,
            valueColor: AlwaysStoppedAnimation<Color>(barColor),
          ),
        ),
      ],
    );
  }
}