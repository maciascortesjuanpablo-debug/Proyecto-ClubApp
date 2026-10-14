import 'package:flutter/material.dart';
import '../core/app_colors.dart';

/// Selector desplegable con el mismo estilo que AppTextField. `items` va de valor -> texto visible.
class AppDropdown<T extends Object> extends StatelessWidget {
  final String label;
  final String hint;
  final T? value;
  final Map<T, String> items;
  final ValueChanged<T?> onChanged;

  const AppDropdown({super.key, required this.label, required this.hint, required this.value, required this.items, required this.onChanged});

  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textWhite)),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: AppColors.bgCard,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.bgCardLight),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<T>(
              value: value,
              isExpanded: true,
              dropdownColor: AppColors.bgCard,
              iconEnabledColor: AppColors.textGray,
              style: const TextStyle(color: AppColors.textWhite, fontSize: 14),
              hint: Text(hint, style: const TextStyle(color: AppColors.textGray)),

              onChanged: onChanged,
              items: [for (final e in items.entries) DropdownMenuItem<T>(value: e.key, child: Text(e.value))],
            ),
          ),
        ),
      ]);
}