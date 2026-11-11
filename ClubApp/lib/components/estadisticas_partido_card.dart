import 'package:flutter/material.dart';
import '../core/app_colors.dart';
import '../models/models.dart';
import '../services/stats_service.dart';
import 'ui_kit.dart';

/// Lo que pasó en un partido jugador por jugador: goles, asistencias y tarjetas. Es de consulta y lo ve cualquiera.
class EstadisticasPartidoCard extends StatefulWidget {
  final Object eventoId;
  const EstadisticasPartidoCard({super.key, required this.eventoId});

  @override
  State<EstadisticasPartidoCard> createState() => _EstadisticasPartidoCardState();
}

class _EstadisticasPartidoCardState extends State<EstadisticasPartidoCard> {
  List<EstadisticaJugadorPartido>? _lista;
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    final r = await StatsService.delPartido(widget.eventoId);
    if (!mounted) return;
    setState(() {
      _cargando = false;
      _lista = r.dato;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_cargando) return const Padding(padding: EdgeInsets.symmetric(vertical: 16), child: Center(child: SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2))));
    final jugadores = (_lista ?? []).where((s) => s.tieneAlgo).toList();

    // Agrupa por equipo
    final porEquipo = <String, List<EstadisticaJugadorPartido>>{};
    for (final s in jugadores) {
      porEquipo.putIfAbsent(s.equipo, () => []).add(s);
    }
    return TarjetaBase(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Estadísticas del partido', style: TextStyle(fontSize: 15, color: AppColors.textWhite, fontWeight: FontWeight.bold)),
        if (jugadores.isEmpty)
          const Padding(padding: EdgeInsets.only(top: 8), child: Text('Todavía no se han registrado goles, asistencias ni tarjetas.', style: TextStyle(fontSize: 12.5, color: AppColors.textGray))),
        for (final e in porEquipo.entries) ...[
          const SizedBox(height: 14),
          Text(e.key, style: const TextStyle(fontSize: 12.5, color: AppColors.secondary, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          for (final s in e.value..sort((a, b) => b.goles != a.goles ? b.goles.compareTo(a.goles) : b.asistencias.compareTo(a.asistencias)))
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(children: [
                Expanded(child: Text(s.nombre, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppColors.textWhite, fontSize: 13.5))),
                if (s.goles > 0) _dato(Icons.sports_soccer, '${s.goles}', AppColors.orange),
                if (s.asistencias > 0) _dato(Icons.handshake_outlined, '${s.asistencias}', AppColors.secondary),
                if (s.amarillas > 0) _dato(Icons.style, '${s.amarillas}', AppColors.warning),
                if (s.rojas > 0) _dato(Icons.style, '${s.rojas}', AppColors.error),
              ]),
            ),
        ],
      ]),
    );
  }

  Widget _dato(IconData icono, String valor, Color color) => Padding(
        padding: const EdgeInsets.only(left: 12),
        child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(icono, size: 15, color: color), const SizedBox(width: 3), Text(valor, style: const TextStyle(fontSize: 13, color: AppColors.textWhite, fontWeight: FontWeight.bold))]),
      );
}