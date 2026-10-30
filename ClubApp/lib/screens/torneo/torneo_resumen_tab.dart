import 'package:flutter/material.dart';
import '../../components/charts.dart';
import '../../components/partido_tile.dart';
import '../../components/tournament_chip.dart';
import '../../components/ui_kit.dart';
import '../../core/app_colors.dart';
import '../../models/models.dart';
import '../event_detail_page.dart';

/// Resumen del torneo: estado general, avance, goles, líder, próximo y último partido, goleadores
class TorneoResumenTab extends StatelessWidget {
  final ResumenTorneo resumen;
  final Future<void> Function() onRecargar;
  const TorneoResumenTab({super.key, required this.resumen, required this.onRecargar});

  @override
  Widget build(BuildContext context) {
    final r = resumen;
    final t = r.torneo;
    final estados = [
      SegmentoDonut('Programados', r.programados, AppColors.primaryLight),
      SegmentoDonut('En vivo', r.enVivo, AppColors.success),
      SegmentoDonut('Finalizados', r.finalizados, AppColors.textGray),
      SegmentoDonut('Aplazados', r.aplazados, AppColors.warning),
      SegmentoDonut('Cancelados', r.cancelados, AppColors.error),
    ].where((s) => s.valor > 0).toList();

    return RefreshIndicator(
      onRefresh: onRecargar,
      child: ListView(physics: const AlwaysScrollableScrollPhysics(), padding: const EdgeInsets.fromLTRB(16, 16, 16, 40), children: [
        // Cabecera
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: AppColors.blue, borderRadius: BorderRadius.circular(20)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              TournamentChip(t.estado, color: AppColors.textWhite),
              const Spacer(),
              if (t.jornadaTotal != null) Text('Jornada ${t.jornadaActual}/${t.jornadaTotal}', style: TextStyle(fontSize: 12, color: AppColors.textWhite.withValues(alpha: 0.8))),
            ]),
            const SizedBox(height: 14),
            Text(t.nombre, style: const TextStyle(fontSize: 22, color: AppColors.textWhite, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text([t.deporte, t.formato, if (t.ciudad != null) t.ciudad!].where((e) => e.isNotEmpty).join(' · '), style: TextStyle(fontSize: 13, color: AppColors.textWhite.withValues(alpha: 0.75))),
            if (t.organizador.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 8), child: Text('Organiza ${t.organizador}', style: TextStyle(fontSize: 12, color: AppColors.textWhite.withValues(alpha: 0.7)))),
          ]),
        ),
        const SizedBox(height: 14),
        // Progreso
        Row(children: [
          Expanded(child: _anillo(r.ocupacion, '${r.equiposAceptados}/${r.equiposMax == 0 ? '-' : r.equiposMax}', 'Equipos', AppColors.secondary)),
          const SizedBox(width: 10),
          Expanded(child: _anillo(r.avance, '${(r.avance * 100).round()}%', 'Partidos jugados', AppColors.success)),
        ]),
        const SizedBox(height: 10),
        KpiGrid([
          KpiTile(icono: Icons.sports_soccer, valor: '${r.golesTotal}', etiqueta: 'Goles', color: AppColors.orange, detalle: r.golesPromedio > 0 ? '${r.golesPromedio} por partido' : null),
          KpiTile(icono: Icons.event_available, valor: '${r.partidosTotal}', etiqueta: 'Partidos', color: AppColors.primaryLight, detalle: r.enVivo > 0 ? '${r.enVivo} en vivo' : '${r.programados} por jugar'),
        ]),
        if (r.lider != null) ...[
          const SeccionTitulo('Líder del torneo'),
          TarjetaBase(
            child: Row(children: [
              const Icon(Icons.workspace_premium, color: AppColors.warning, size: 32),
              const SizedBox(width: 12),
              Expanded(child: Text(r.lider!, style: const TextStyle(fontSize: 16, color: AppColors.textWhite, fontWeight: FontWeight.bold))),
              Text('${r.liderPuntos} pts', style: const TextStyle(fontSize: 15, color: AppColors.secondary, fontWeight: FontWeight.bold)),
            ]),
          ),
        ],
        if (estados.isNotEmpty) ...[
          const SeccionTitulo('Estado de los partidos'),
          TarjetaBase(
            child: Row(children: [
              DonutChart(segmentos: estados, centro: '${r.partidosTotal}', subcentro: 'partidos', tamano: 120),
              const SizedBox(width: 20),
              Expanded(child: LeyendaChart(estados)),
            ]),
          ),
        ],
        if (r.proximo != null) ...[
          const SeccionTitulo('Próximo partido'),
          PartidoTile(partido: r.proximo!, mostrarTorneo: false, mostrarFecha: true, onTap: () => _abrir(context, r.proximo!)),
        ],
        if (r.ultimo != null) ...[
          const SeccionTitulo('Último resultado'),
          PartidoTile(partido: r.ultimo!, mostrarTorneo: false, mostrarFecha: true, onTap: () => _abrir(context, r.ultimo!)),
        ],
        if (r.goleadores.isNotEmpty) ...[
          const SeccionTitulo('Goleadores'),
          TarjetaBase(
            child: Column(children: [
              for (var i = 0; i < r.goleadores.length; i++)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(children: [
                    SizedBox(width: 22, child: Text('${i + 1}', style: const TextStyle(color: AppColors.textGray, fontWeight: FontWeight.bold))),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(r.goleadores[i].nombre, style: const TextStyle(color: AppColors.textWhite, fontWeight: FontWeight.w600)),
                      Text(r.goleadores[i].equipo, style: const TextStyle(fontSize: 11.5, color: AppColors.textGray)),
                    ])),
                    const Icon(Icons.sports_soccer, size: 14, color: AppColors.orange),
                    const SizedBox(width: 6),
                    Text('${r.goleadores[i].goles}', style: const TextStyle(fontSize: 16, color: AppColors.textWhite, fontWeight: FontWeight.bold)),
                  ]),
                ),
            ]),
          ),
        ],
      ]),
    );
  }

  Widget _anillo(double valor, String texto, String etiqueta, Color color) => TarjetaBase(
        child: Row(children: [
          AnilloProgreso(valor: valor, texto: texto, color: color, tamano: 62),
          const SizedBox(width: 12),
          Expanded(child: Text(etiqueta, style: const TextStyle(fontSize: 12.5, color: AppColors.textGray))),
        ]),
      );

  void _abrir(BuildContext context, Partido p) => Navigator.push(context, MaterialPageRoute(builder: (_) => EventDetailPage(eventoId: p.id)));
}
