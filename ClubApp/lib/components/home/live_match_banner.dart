import 'package:flutter/material.dart';
import '../../core/app_colors.dart';
import '../../services/home_services.dart';

class LiveMatchBanner extends StatelessWidget {
  final Map<String, dynamic>? partido;
  final VoidCallback onVerDetalles;

  const LiveMatchBanner({super.key, this.partido, required this.onVerDetalles});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: AppColors.blue, borderRadius: BorderRadius.circular(16)),
          child: partido == null ? _vacio : _conPartido(partido!),
        ),
      );

  Widget get _vacio => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('No hay partidos en vivo', style: TextStyle(fontSize: 16, color: AppColors.textWhite, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text('Cuando empiece uno lo verás aquí', style: TextStyle(fontSize: 12, color: AppColors.textWhite.withValues(alpha: 0.7))),
      ]);

  Widget _punto(double size) => Container(width: size, height: size, decoration: const BoxDecoration(color: AppColors.success, shape: BoxShape.circle));

  Widget _conPartido(Map<String, dynamic> p) {
    final jornada = p['torneos']?['jornada_actual'];
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [

      Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(color: AppColors.textWhite.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(8)),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              _punto(6),
              const SizedBox(width: 6),
              Text('Partido en curso', style: TextStyle(fontSize: 10, color: AppColors.textWhite.withValues(alpha: 0.85))),
            ]),
          ),
          const SizedBox(height: 14),
          Text((p['torneos']?['nombre'] ?? '').toString(),
              maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 20, color: AppColors.textWhite, fontWeight: FontWeight.bold)),
          if (jornada != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text('Jornada $jornada', style: TextStyle(fontSize: 12, color: AppColors.textWhite.withValues(alpha: 0.6))),
            ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: onVerDetalles,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.textWhite,
              foregroundColor: AppColors.bgDark,
              elevation: 0,
              shape: const StadiumBorder(),
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 8),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text('Ver detalles', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),

          ),
        ]),
      ),
      const SizedBox(width: 12),
      Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
        Text("${HomeService.minutoAproximado(p)}'", style: const TextStyle(fontSize: 34, color: AppColors.textWhite, fontWeight: FontWeight.bold)),
        Row(mainAxisSize: MainAxisSize.min, children: [
          _punto(6),
          const SizedBox(width: 4),
          const Text('En vivo', style: TextStyle(fontSize: 12, color: AppColors.success, fontWeight: FontWeight.bold)),
        ]),
      ]),
    ]);
  }
}