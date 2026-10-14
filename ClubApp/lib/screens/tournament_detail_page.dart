import 'package:flutter/material.dart';
import '../core/app_colors.dart';
import '../components/tournament_chip.dart';

class TournamentDetailPage extends StatelessWidget {
  final Map<String, dynamic> torneo;

  const TournamentDetailPage({super.key, required this.torneo});

  String _fecha(String? iso) {
    final d = DateTime.tryParse(iso ?? '')?.toLocal();
    return d == null ? '-' : '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    final t = torneo;
    final estado = (t['estado'] ?? 'Sin estado').toString();
    final actual = t['jornada_actual'] ?? 0;
    final organizador = t['usuarios'] == null ? '-' : '${t['usuarios']['nombre'] ?? ''} ${t['usuarios']['apellido'] ?? ''}'.trim();

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(backgroundColor: AppColors.bgDark, elevation: 0, title: const Text('Torneo')),
      body: ListView(padding: const EdgeInsets.all(20), children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: AppColors.blue, borderRadius: BorderRadius.circular(16)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            TournamentChip(estado, color: AppColors.textWhite),
            const SizedBox(height: 14),

            Text((t['nombre'] ?? '').toString(), style: const TextStyle(fontSize: 22, color: AppColors.textWhite, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text('${t['deportes']?['nombre'] ?? ''} · ${t['formatos']?['nombre'] ?? ''}', style: TextStyle(fontSize: 13, color: AppColors.textWhite.withValues(alpha: 0.7))),
          ]),
        ),
        const SizedBox(height: 20),
        _fila(Icons.location_on_outlined, 'Ciudad', (t['ciudad'] ?? 'Sin definir').toString()),
        _fila(Icons.groups_outlined, 'Equipos máximos', '${t['max_equipos'] ?? '-'}'),
        _fila(Icons.flag_outlined, 'Jornada', t['jornada_total'] != null ? '$actual de ${t['jornada_total']}' : '$actual'),
        _fila(Icons.person_outline, 'Organizador', organizador.isEmpty ? '-' : organizador),
        _fila(Icons.event_outlined, 'Creado', _fecha(t['creado_en']?.toString())),
      ]),
    );
  }

  Widget _fila(IconData icono, String titulo, String valor) => Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: AppColors.bgCard, borderRadius: BorderRadius.circular(12)),
        child: Row(children: [
          Icon(icono, color: AppColors.secondary, size: 22),
          const SizedBox(width: 12),
          Text(titulo, style: const TextStyle(fontSize: 13, color: Color.fromARGB(255, 232, 235, 238))),
          const SizedBox(width: 12),
          Expanded(child: Text(valor, textAlign: TextAlign.end, style: const TextStyle(fontSize: 14, color: AppColors.textWhite, fontWeight: FontWeight.w600))),
        ]),
      );
}