import 'package:flutter/material.dart';
import '../../core/app_colors.dart';
import '../../services/home_services.dart';
import '../activity_item.dart';
import 'section_title.dart';

class RecentActivity extends StatelessWidget {
  final List actividad;
  const RecentActivity({super.key, required this.actividad});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const SectionTitle('Actividad reciente'),
          if (actividad.isEmpty)
            const Text('Sin actividad reciente', style: TextStyle(color: AppColors.textGray))
          else
            for (final raw in actividad)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: ActivityItem(
                  title: ((raw as Map<String, dynamic>)['titulo'] ?? '').toString(),
                  time: HomeService.hace(raw['fecha']?.toString()),
                  nuevo: raw['tipo'] == 'notificacion',
                ),
              ),
          const SizedBox(height: 18),
        ]),
      );
}