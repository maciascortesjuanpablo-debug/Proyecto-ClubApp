import 'package:flutter/material.dart';
import '../../components/month_grid.dart';
import '../../components/partido_tile.dart';
import '../../components/ui_kit.dart';
import '../../core/app_colors.dart';
import '../../core/calendar_utils.dart';
import '../../models/models.dart';
import '../../services/tournament_service.dart';
import '../event_detail_page.dart';
import '../event_form_page.dart';

/// Calendario de programación del torneo (solo organizador dueño y admin): se elige un día y se programa el partido.
class TorneoCalendarioTab extends StatefulWidget {
  final Torneo torneo;
  final Future<void> Function() onCambio;
  const TorneoCalendarioTab({super.key, required this.torneo, required this.onCambio});

  @override
  State<TorneoCalendarioTab> createState() => _TorneoCalendarioTabState();
}

class _TorneoCalendarioTabState extends State<TorneoCalendarioTab> {
  DateTime _mes = DateUtils.dateOnly(DateTime.now());
  DateTime _dia = DateUtils.dateOnly(DateTime.now());
  List<Partido> _eventos = [];
  String? _error;
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    final r = await TournamentService.eventos(widget.torneo.id);
    if (!mounted) return;
    setState(() {
      _cargando = false;
      _error = r.error;
      _eventos = r.dato ?? [];
    });
  }

  void _cambiarMes(int d) => setState(() => _mes = DateTime(_mes.year, _mes.month + d, 1));

  Future<void> _programar() async {
    final creado = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => EventFormPage(fechaInicial: _dia, torneoId: widget.torneo.id, torneoNombre: widget.torneo.nombre)),
    );
    if (creado == true) {
      await _cargar();
      await widget.onCambio();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_cargando) return const Center(child: CircularProgressIndicator());
    if (_error != null) return Center(child: Text(_error!, style: const TextStyle(color: AppColors.textGray)));
    final porDia = <String, int>{};
    for (final e in _eventos) {
      porDia[e.diaIso] = (porDia[e.diaIso] ?? 0) + 1;
    }
    final delDia = _eventos.where((e) => e.diaIso == isoFecha(_dia)).toList();
    final bloqueado = diaBloqueado(_dia);
    final cerrado = widget.torneo.cerrado;

    return RefreshIndicator(
      onRefresh: _cargar,
      child: ListView(physics: const AlwaysScrollableScrollPhysics(), padding: const EdgeInsets.fromLTRB(16, 12, 16, 40), children: [
        Row(children: [
          IconButton(onPressed: () => _cambiarMes(-1), icon: const Icon(Icons.chevron_left, color: AppColors.textWhite)),
          Expanded(child: Center(child: Text('${nombresMes[_mes.month - 1]} ${_mes.year}', style: const TextStyle(fontSize: 16, color: AppColors.textWhite, fontWeight: FontWeight.bold)))),
          IconButton(onPressed: () => _cambiarMes(1), icon: const Icon(Icons.chevron_right, color: AppColors.textWhite)),
        ]),
        TarjetaBase(padding: const EdgeInsets.all(10), child: MonthGrid(mes: _mes, seleccionado: _dia, eventosPorDia: porDia, onSeleccionar: (d) => setState(() => _dia = d))),
        SeccionTitulo(fechaLarga(_dia)),
        if (!cerrado)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: FilledButton.icon(
              onPressed: bloqueado ? null : _programar,
              icon: const Icon(Icons.add),
              label: Text(bloqueado ? (diaPasado(_dia) ? 'Este día ya pasó' : 'Fuera de los próximos 40 días') : 'Programar partido este día'),
            ),
          ),
        if (delDia.isEmpty) const EstadoVacio(icono: Icons.event_busy_outlined, mensaje: 'No hay partidos programados este día'),
        for (final p in delDia)
          PartidoTile(
            partido: p,
            mostrarTorneo: false,
            onTap: () async {
              await Navigator.push(context, MaterialPageRoute(builder: (_) => EventDetailPage(eventoId: p.id)));
              await _cargar();
              await widget.onCambio();
            },
          ),
      ]),
    );
  }
}
