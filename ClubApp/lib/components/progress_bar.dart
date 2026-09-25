import 'package:flutter/material.dart';
import '../core/app_colors.dart';

class ProgressBar extends StatelessWidget {
  final double value; // 0.0 to 1.0
  final String label;

  const ProgressBar({
    Key? key,
    required this.value,
    required this.label,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: AppColors.secondary,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: value,
            minHeight: 3,
            backgroundColor: AppColors.bgCard,
            valueColor: AlwaysStoppedAnimation<Color>(
              AppColors.secondary,
            ),
          ),
        ),
      ],
    );
  }
}