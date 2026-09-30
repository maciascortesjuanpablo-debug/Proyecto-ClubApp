import 'package:flutter/material.dart';
import '../core/app_colors.dart';

class QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onPressed;

  const QuickActionButton({Key? key, required this.icon, required this.label, this.onPressed}) : super(key: key);

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onPressed,
    child: Column(
      children: [
        Container(
          width: 60, height: 60,
          decoration: BoxDecoration(color: AppColors.bgCard, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.primaryLight)),
          child: Center(child: Icon(icon, color: AppColors.secondary, size: 28)),
        ),
        const SizedBox(height: 8),
        Text(label, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppColors.textGray), textAlign: TextAlign.center),
      ],
    ),
  );
}