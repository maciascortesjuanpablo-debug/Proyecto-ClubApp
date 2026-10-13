import 'package:flutter/material.dart';
import '../../core/app_colors.dart';


class SectionTitle extends StatelessWidget {
  final String text;
  final String? accion;
  final VoidCallback? onAccion;

  const SectionTitle(this.text, {super.key, this.accion, this.onAccion});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(text, style: const TextStyle(fontSize: 18, color: AppColors.textWhite, fontWeight: FontWeight.bold)),
          if (accion != null)
            GestureDetector(
              onTap: onAccion,
              child: Text(accion!, style: const TextStyle(fontSize: 12, color: AppColors.secondary, fontWeight: FontWeight.w600)),
            ),
        ]),
      );
}