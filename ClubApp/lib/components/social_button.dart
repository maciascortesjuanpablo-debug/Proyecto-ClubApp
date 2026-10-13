import 'package:flutter/material.dart';
import '../core/app_colors.dart';

class SocialButton extends StatelessWidget {
  final String icon;
  final String label;
  final VoidCallback? onPressed;
  final bool isExpanded;

  const SocialButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onPressed,
    this.isExpanded = true,
  });

  @override
  Widget build(BuildContext context) {
    Widget button = ElevatedButton.icon(
      onPressed: onPressed,
      icon: Text(
        icon,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary.withValues(alpha: 0.8),
        foregroundColor: AppColors.textWhite,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 0,
        padding: const EdgeInsets.symmetric(vertical: 14),
      ),
    );

    if (isExpanded) {
      return SizedBox(width: double.infinity, child: button);
    }
    return button;
  }
}