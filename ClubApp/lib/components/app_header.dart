import 'package:flutter/material.dart';
import '../core/app_colors.dart';

class AppHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool showLogo;
  final String? logoAssetPath;
  final double logoSize;

  const AppHeader({
    Key? key,
    required this.title,
    required this.subtitle,
    this.showLogo = true,
    this.logoAssetPath,
    this.logoSize = 70,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (showLogo) ...[
          if (logoAssetPath != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.asset(
                logoAssetPath!,
                width: logoSize,
                height: logoSize,
                fit: BoxFit.contain,
              ),
            )
          else
            Container(
              width: logoSize,
              height: logoSize,
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Center(
                child: Text(
                  'c',
                  style: TextStyle(
                    color: AppColors.textWhite,
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
        Text(
          title,
          style: const TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: AppColors.textWhite,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          subtitle,
          style: const TextStyle(
            fontSize: 13,
            color: AppColors.textGray,
          ),
        ),
      ],
    );
  }
}