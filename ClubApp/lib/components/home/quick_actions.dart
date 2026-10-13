import 'package:flutter/material.dart';
import '../../core/app_colors.dart';
import 'section_title.dart';

class QuickActions extends StatelessWidget {
  final VoidCallback onCalendario;
  final VoidCallback onTorneos;
  final VoidCallback onEquipo;
  final VoidCallback onEstadisticas;

  const QuickActions({
    super.key,
    required this.onCalendario,
    required this.onTorneos,
    required this.onEquipo,
    required this.onEstadisticas,
  });

  @override
  Widget build(BuildContext context) {
    final acciones = [
      ('Calendario', Icons.calendar_month, onCalendario),
      ('Torneos', Icons.local_fire_department, onTorneos),
      ('Mi equipo', Icons.groups, onEquipo),
      ('Estadísticas', Icons.show_chart, onEstadisticas),
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const SectionTitle('Acciones rápidas'),
        Row(children: [
          for (final (i, a) in acciones.indexed) ...[

            if (i > 0) const SizedBox(width: 12),
            Expanded(child: _tile(a.$1, a.$2, a.$3)),
          ],
        ]),
        const SizedBox(height: 28),
      ]),
    );
  }

  Widget _tile(String label, IconData icon, VoidCallback onTap) => Material(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(color: AppColors.blue, borderRadius: BorderRadius.circular(10)),
                child: Icon(icon, color: AppColors.textWhite, size: 20),
              ),
              const SizedBox(height: 8),
              Text(label, maxLines: 1, style: const TextStyle(fontSize: 10, color: AppColors.textWhite, fontWeight: FontWeight.bold)),
            ]),
          ),
        ),
      );
}