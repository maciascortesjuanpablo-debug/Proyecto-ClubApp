import 'package:flutter/material.dart';
import '../core/app_colors.dart';

Color colorEstado(String estado) => switch (estado) {
      'Activo' => AppColors.success,
      'Finalizado' => AppColors.textGrayDark,
      _ => AppColors.primaryLight,
    };

/// Etiqueta pequeña con texto (y icono opcional) de un color
class TournamentChip extends StatelessWidget {
  final String texto;
  final Color color;
  final IconData? icono;

  const TournamentChip(this.texto, {super.key, required this.color, this.icono});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          if (icono != null) ...[Icon(icono, size: 11, color: color), const SizedBox(width: 4)],
          Text(texto, style: TextStyle(fontSize: 10.5, color: color, fontWeight: FontWeight.bold)),
        ]),
      );
}