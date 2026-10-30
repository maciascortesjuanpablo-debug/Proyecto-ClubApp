import 'package:flutter/material.dart';
import '../core/app_colors.dart';
import '../core/calendar_utils.dart';
import '../models/models.dart';
import 'tournament_chip.dart';
import 'ui_kit.dart';

/// Tarjeta de un partido: equipos con escudo, marcador u hora, estado y etiquetas opcionales
class PartidoTile extends StatelessWidget {
  final Partido partido;
  final VoidCallback? onTap;
  final bool mostrarTorneo;
  final bool mostrarFecha;
  final String? etiqueta; // ej. "Mi equipo", "Principal"
  final Object? destacarEquipoId; // resalta el resultado para este equipo (G/E/P)

  const PartidoTile({super.key, required this.partido, this.onTap, this.mostrarTorneo = true, this.mostrarFecha = false, this.etiqueta, this.destacarEquipoId});

  @override
  Widget build(BuildContext context) {
    final p = partido;
    final resultado = destacarEquipoId == null ? null : p.resultadoPara(destacarEquipoId!);
    final colorRes = switch (resultado) { 'G' => AppColors.success, 'P' => AppColors.error, _ => AppColors.warning };
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TarjetaBase(
        onTap: onTap,
        padding: const EdgeInsets.all(14),
        child: p.esPartido ? _partido(colorRes, resultado) : _otroEvento(),
      ),
    );
  }

  Widget _cabecera() => Row(children: [
        if (mostrarTorneo && partido.torneoNombre.isNotEmpty) Expanded(child: Text(partido.torneoNombre, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11, color: AppColors.primaryLight, fontWeight: FontWeight.w700))) else const Spacer(),
        Text(mostrarFecha && partido.fecha != null ? '${fechaLarga(partido.fecha!)} · ${partido.hora}' : partido.hora, style: const TextStyle(fontSize: 12, color: AppColors.textGray, fontWeight: FontWeight.w600)),
      ]);

  Widget _partido(Color colorRes, String? resultado) {
    final p = partido;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _cabecera(),
      const SizedBox(height: 12),
      Row(children: [
        Expanded(child: _equipo(p.nombreLocal, p.local?.logoUrl)),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(color: AppColors.bgCardLight.withValues(alpha: 0.5), borderRadius: BorderRadius.circular(10)),
          child: Text(p.tieneMarcador ? '${p.resultadoLocal} - ${p.resultadoVisitante}' : 'VS', style: const TextStyle(fontSize: 17, color: AppColors.textWhite, fontWeight: FontWeight.bold)),
        ),
        Expanded(child: _equipo(p.nombreVisitante, p.visitante?.logoUrl)),
      ]),
      const SizedBox(height: 10),
      Wrap(spacing: 6, runSpacing: 6, crossAxisAlignment: WrapCrossAlignment.center, children: [
        TournamentChip(p.estado, color: colorEstadoPartido(p.estado)),
        if (resultado != null) TournamentChip(switch (resultado) { 'G' => 'Victoria', 'P' => 'Derrota', _ => 'Empate' }, color: colorRes),
        if (etiqueta != null) TournamentChip(etiqueta!, color: AppColors.secondary, icono: Icons.star),
        if (p.sede != null) Row(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.location_on_outlined, size: 13, color: AppColors.textGray), const SizedBox(width: 3), Text(p.sede!, style: const TextStyle(fontSize: 11.5, color: AppColors.textGray))]),
      ]),
    ]);
  }

  Widget _otroEvento() => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _cabecera(),
        const SizedBox(height: 6),
        Text(partido.tipo, style: const TextStyle(fontSize: 15, color: AppColors.textWhite, fontWeight: FontWeight.bold)),
        if (partido.sede != null) Padding(padding: const EdgeInsets.only(top: 4), child: Text(partido.sede!, style: const TextStyle(fontSize: 12, color: AppColors.textGray))),
      ]);

  Widget _equipo(String nombre, String? logo) => Column(children: [
        EquipoAvatar(nombre: nombre, logoUrl: logo, tamano: 40),
        const SizedBox(height: 6),
        Text(nombre, maxLines: 2, textAlign: TextAlign.center, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12.5, color: AppColors.textWhite, fontWeight: FontWeight.w600)),
      ]);
}
