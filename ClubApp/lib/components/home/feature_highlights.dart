import 'package:flutter/material.dart';
import '../../core/app_colors.dart';
import 'section_title.dart';

class FeatureHighlights extends StatelessWidget {
  final void Function(String) onTap;
  const FeatureHighlights({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const SectionTitle('¿Qué puedes hacer en ClubApp?'),
          Row(children: [
            _item('Torneos', 'Crea y administra', Icons.emoji_events),
            const SizedBox(width: 12),
            _item('Equipos', 'Gestiona tu plantilla', Icons.group),
          ]),
          const SizedBox(height: 12),
          Row(children: [
            _item('Estadísticas', 'Sigue tu rendimiento', Icons.bar_chart),
            const SizedBox(width: 12),
            _item('ScoutAI', 'Tu asistente deportivo', Icons.smart_toy_outlined),
          ]),
          const SizedBox(height: 24),
        ]),
      );

  Widget _item(String titulo, String desc, IconData icono) => Expanded(
        child: InkWell(
          onTap: () => onTap(titulo),
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.bgCard,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.primaryLight.withValues(alpha: 0.25)),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Icon(icono, color: AppColors.secondary, size: 26),
              const SizedBox(height: 10),
              Text(titulo,
                  style: const TextStyle(color: AppColors.textWhite, fontSize: 14, fontWeight: FontWeight.w600)),
              const SizedBox(height: 2),
              Text(desc, style: const TextStyle(color: AppColors.textGray, fontSize: 11)),
            ]),
          ),
        ),
      );
}