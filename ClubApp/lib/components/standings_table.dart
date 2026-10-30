import 'package:flutter/material.dart';
import '../core/app_colors.dart';
import '../models/models.dart';
import 'ui_kit.dart';

/// Tabla de posiciones de un torneo. Los primeros lugares llevan un acento de color y
/// los equipos de [resaltar] (por ejemplo el del jugador o entrenador) se marcan.
class TablaPosiciones extends StatelessWidget {
  final List<FilaPosicion> filas;
  final Set<String> resaltar; // ids de equipo
  const TablaPosiciones({super.key, required this.filas, this.resaltar = const {}});

  static const _estiloCab = TextStyle(fontSize: 11, color: AppColors.textGray, fontWeight: FontWeight.bold);

  @override
  Widget build(BuildContext context) {
    if (filas.isEmpty) return const EstadoVacio(icono: Icons.leaderboard_outlined, mensaje: 'La tabla aparecerá cuando haya equipos inscritos y partidos jugados');
    final orden = [...filas]..sort((a, b) => a.posicion != b.posicion ? a.posicion.compareTo(b.posicion) : b.puntos.compareTo(a.puntos));
    return Container(
      decoration: BoxDecoration(color: AppColors.bgCard, borderRadius: BorderRadius.circular(16)),
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
      child: Column(children: [
        Row(children: [
          const SizedBox(width: 26, child: Text('#', style: _estiloCab)),
          const Expanded(child: Text('Equipo', style: _estiloCab)),
          for (final c in const ['PJ', 'G', 'E', 'P', 'DG']) SizedBox(width: 30, child: Text(c, textAlign: TextAlign.center, style: _estiloCab)),
          const SizedBox(width: 38, child: Text('PTS', textAlign: TextAlign.center, style: _estiloCab)),
        ]),
        const Divider(color: AppColors.bgCardLight, height: 16),
        for (var i = 0; i < orden.length; i++) _fila(orden[i], i, orden.length),
      ]),
    );
  }

  Widget _fila(FilaPosicion f, int indice, int total) {
    final lugar = indice + 1;
    final acento = lugar == 1 ? AppColors.warning : (lugar <= 3 ? AppColors.success : Colors.transparent);
    final mio = f.equipoId != null && resaltar.contains('${f.equipoId}');
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(color: mio ? AppColors.primaryLight.withValues(alpha: 0.14) : Colors.transparent, borderRadius: BorderRadius.circular(10)),
      child: Row(children: [
        Container(width: 3, height: 22, margin: const EdgeInsets.only(right: 5, left: 2), decoration: BoxDecoration(color: acento, borderRadius: BorderRadius.circular(2))),
        SizedBox(width: 19, child: Text('$lugar', style: const TextStyle(fontSize: 12.5, color: AppColors.textWhite, fontWeight: FontWeight.bold))),
        EquipoAvatar(nombre: f.equipo, logoUrl: f.logoUrl, tamano: 26),
        const SizedBox(width: 8),
        Expanded(child: Text(f.equipo, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 13, color: AppColors.textWhite, fontWeight: mio ? FontWeight.bold : FontWeight.w500))),
        for (final v in [f.jugados, f.victorias, f.empates, f.derrotas]) SizedBox(width: 30, child: Text('$v', textAlign: TextAlign.center, style: const TextStyle(fontSize: 12.5, color: AppColors.textGray))),
        SizedBox(width: 30, child: Text(f.diferencia > 0 ? '+${f.diferencia}' : '${f.diferencia}', textAlign: TextAlign.center, style: TextStyle(fontSize: 12.5, color: f.diferencia < 0 ? AppColors.error : AppColors.textGray))),
        SizedBox(width: 38, child: Text('${f.puntos}', textAlign: TextAlign.center, style: const TextStyle(fontSize: 14, color: AppColors.secondary, fontWeight: FontWeight.bold))),
      ]),
    );
  }
}
