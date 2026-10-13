import 'package:flutter/material.dart';
import '../../core/app_colors.dart';
import 'section_title.dart';

class TournamentsPreview extends StatelessWidget {
  final List torneos;
  final VoidCallback onVerTodos;

  const TournamentsPreview({super.key, required this.torneos, required this.onVerTodos});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          SectionTitle('Torneos activos', accion: 'Ver todos', onAccion: onVerTodos),
          if (torneos.isEmpty)
            const Text('Aún no hay torneos activos', style: TextStyle(color: AppColors.textGray))
          else
            ...torneos.map((t) => _card(t as Map<String, dynamic>)),
          const SizedBox(height: 24),
        ]),
      );

  Widget _card(Map<String, dynamic> t) => InkWell(
        onTap: onVerTodos,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.bgCard,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.primaryLight.withValues(alpha: 0.2)),
          ),
          child: Row(children: [
            const Icon(Icons.emoji_events, color: AppColors.primaryLight),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text((t['nombre'] ?? '').toString(),
                    style: const TextStyle(color: AppColors.textWhite, fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(
                  '${t['deportes']?['nombre'] ?? ''} · ${t['formatos']?['nombre'] ?? ''}'
                  '${t['ciudad'] != null ? ' · ${t['ciudad']}' : ''}',
                  style: const TextStyle(color: AppColors.textGray, fontSize: 12),
                ),
              ]),
            ),
            const Icon(Icons.chevron_right, color: AppColors.textGray),
          ]),
        ),
      );
}