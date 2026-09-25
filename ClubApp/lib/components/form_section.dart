import 'package:flutter/material.dart';
import '../core/app_colors.dart';

class FormSection extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<Widget> children;
  final EdgeInsets padding;

  const FormSection({
    Key? key,
    required this.title,
    required this.subtitle,
    required this.children,
    this.padding = const EdgeInsets.only(bottom: 20),
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textWhite,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textGray,
            ),
          ),
          const SizedBox(height: 20),
          ...children,
        ],
      ),
    );
  }
}