import 'package:flutter/material.dart';
import '../core/app_colors.dart';

class NavigationLink extends StatelessWidget {
  final String normalText;
  final String actionText;
  final VoidCallback onTap;

  const NavigationLink({
    Key? key,
    required this.normalText,
    required this.actionText,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: GestureDetector(
        onTap: onTap,
        child: RichText(
          text: TextSpan(
            text: normalText,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textGray,
            ),
            children: [
              TextSpan(
                text: actionText,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.secondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}