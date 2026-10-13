import 'package:flutter/material.dart';
import '../../core/app_colors.dart';
import '../app_button.dart';
import '../stat_card.dart';
import 'section_title.dart';

class HomeStats extends StatelessWidget {
  final bool logueado;
  final Map<String, dynamic>? stats;
  final VoidCallback onLogin;

  const HomeStats({super.key, required this.logueado, this.stats, required this.onLogin});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const SectionTitle('Mis Estadísticas'),
          logueado ? _cards : _invitado,
          const SizedBox(height: 28),
        ]),
      );

  Widget get _cards {
    final semana = (stats?['partidosSemana'] ?? 0) as int;
    return Row(children: [
      _stat('${stats?['partidos'] ?? 0}', 'Partidos', semana > 0 ? '+$semana esta semana' : 'jugados', AppColors.success),
      const SizedBox(width: 12),
      _stat('${stats?['goles'] ?? 0}', 'Goles', 'anotados', AppColors.primaryLight),
      const SizedBox(width: 12),
      _stat('${stats?['torneos'] ?? 0}', 'Torneos', 'Activos', AppColors.success),
    ]);

  }

  Widget _stat(String value, String label, String sub, Color color) =>
      Expanded(child: StatCard(value: value, label: label, subLabel: sub, color: color));

  Widget get _invitado => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: AppColors.bgCard, borderRadius: BorderRadius.circular(12)),
        child: Column(children: [
          const Icon(Icons.lock_outline, color: AppColors.textGray, size: 28),
          const SizedBox(height: 8),
          const Text('Inicia sesión para ver tus partidos, goles y torneos',
              textAlign: TextAlign.center, style: TextStyle(color: AppColors.textGray, fontSize: 13)),
          const SizedBox(height: 14),
          AppButton(label: 'Iniciar sesión', onPressed: onLogin),
        ]),
      );
}