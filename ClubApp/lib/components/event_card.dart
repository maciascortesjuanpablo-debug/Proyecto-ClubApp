import 'package:flutter/material.dart';
import '../core/app_colors.dart';
import '../core/calendar_utils.dart';
import 'tournament_chip.dart';

/// Tarjeta de un evento del calendario (hora, torneo, equipos con marcador, sede y mi relación con él)
class EventCard extends StatelessWidget {
  final Map<String, dynamic> evento;
  final VoidCallback onTap;

  const EventCard({super.key, required this.evento, required this.onTap});

  static const _etiquetaRelacion = {'equipo': 'Mi equipo', 'arbitro': 'Árbitro', 'organizador': 'Organizo'};

  @override
  Widget build(BuildContext context) {
    final e = evento;
    final estado = (e['estado'] ?? 'Programado').toString();
    final partido = e['tipo'] == 'Partido';
    final local = e['equipo_local']?['nombre']?.toString() ?? 'Por definir';
    final visitante = e['equipo_visitante']?['nombre']?.toString() ?? 'Por definir';
    final tieneMarcador = e['resultado_local'] != null && e['resultado_visitante'] != null;
    final sede = e['sedes_canchas']?['nombre']?.toString();
    final relacion = ((e['relacion'] as List?) ?? []).map((r) => _etiquetaRelacion[r]).whereType<String>().toList();

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),

          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              SizedBox(
                width: 54,
                child: Column(children: [
                  Text(horaCorta(e['hora']), style: const TextStyle(fontSize: 17, color: AppColors.textWhite, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  Container(width: 8, height: 8, decoration: BoxDecoration(color: colorEstadoPartido(estado), shape: BoxShape.circle)),
                ]),
              ),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text((e['torneo']?['nombre'] ?? '').toString(), maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11, color: AppColors.primaryLight, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 2),
                  Text(
                    partido ? (tieneMarcador ? '$local  ${e['resultado_local']} - ${e['resultado_visitante']}  $visitante' : '$local  vs  $visitante') : (e['tipo'] ?? 'Evento').toString(),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 15, color: AppColors.textWhite, fontWeight: FontWeight.bold),
                  ),
                  if (sede != null) Padding(padding: const EdgeInsets.only(top: 4), child: Row(children: [const Icon(Icons.location_on_outlined, size: 14, color: AppColors.textGray), const SizedBox(width: 4), Expanded(child: Text(sede, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, color: AppColors.textGray)))])),
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Wrap(spacing: 6, runSpacing: 6, children: [
                      TournamentChip(estado, color: colorEstadoPartido(estado)),
                      for (final r in relacion) TournamentChip(r, color: AppColors.secondary, icono: Icons.star),
                    ]),
                  ),
                ]),
              ),

              const Icon(Icons.chevron_right, color: AppColors.textGray),
            ]),
          ),
        ),
      ),
    );
  }
}