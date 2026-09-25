import 'package:flutter/material.dart';

class AppSpacing {
  // Padding
  static const double paddingXSmall = 4;
  static const double paddingSmall = 8;
  static const double paddingMedium = 12;
  static const double paddingLarge = 16;
  static const double paddingXLarge = 24;
  static const double paddingXXLarge = 40;

  // Screen padding
  static const EdgeInsetsGeometry screenPadding =
      EdgeInsets.symmetric(horizontal: paddingLarge, vertical: 20);

  // Form field spacing
  static const SizedBox verticalSmall = SizedBox(height: paddingSmall);
  static const SizedBox verticalMedium = SizedBox(height: paddingMedium);
  static const SizedBox verticalLarge = SizedBox(height: paddingLarge);
  static const SizedBox verticalXLarge = SizedBox(height: paddingXLarge);
  static const SizedBox verticalXXLarge = SizedBox(height: paddingXXLarge);

  // Horizontal spacing
  static const SizedBox horizontalSmall = SizedBox(width: paddingSmall);
  static const SizedBox horizontalMedium = SizedBox(width: paddingMedium);
  static const SizedBox horizontalLarge = SizedBox(width: paddingLarge);
}

class AppSizes {
  // Logo sizes
  static const double logoSmall = 60;
  static const double logoMedium = 70;
  static const double logoLarge = 80;

  // Border radius
  static const double borderRadiusSmall = 8;
  static const double borderRadiusMedium = 12;
  static const double borderRadiusLarge = 16;

  // Icon sizes
  static const double iconSmall = 16;
  static const double iconMedium = 24;
  static const double iconLarge = 32;
}

class AppDurations {
  static const Duration fast = Duration(milliseconds: 200);
  static const Duration normal = Duration(milliseconds: 300);
  static const Duration slow = Duration(milliseconds: 500);
  static const Duration splashDuration = Duration(seconds: 3);
}