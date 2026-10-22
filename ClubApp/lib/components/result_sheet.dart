import 'package:flutter/material.dart';
import '../core/app_colors.dart';
import '../core/calendar_utils.dart';
import '../services/calendar_service.dart';
import 'app_button.dart';
import 'app_dropdown.dart';

/// Hoja para cambiar el estado y el marcador de un partido. Devuelve true si se guardó.
Future<bool> mostrarResultado(BuildContext context, Map<String, dynamic> evento) async =>
    await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.bgCard,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _ResultSheet(evento: evento),
    ) ??
    false;

class _ResultSheet extends StatefulWidget {
  final Map<String, dynamic> evento;

  const _ResultSheet({required this.evento});

  @override
  State<_ResultSheet> createState() => _ResultSheetState();
}

class _ResultSheetState extends State<_ResultSheet> {
  late String _estado = estadosPartido.contains(widget.evento['estado']) ? widget.evento['estado'] as String : 'Programado';
  late int _local = (widget.evento['resultado_local'] as num?)?.toInt() ?? 0;
  late int _visitante = (widget.evento['resultado_visitante'] as num?)?.toInt() ?? 0;
  bool _guardando = false;

  String? _error;

  Future<void> _guardar() async {
    setState(() {
      _guardando = true;
      _error = null;
    });
    // El marcador solo cuenta cuando el partido está en juego o terminado
    final conMarcador = _estado == 'En vivo' || _estado == 'Finalizado';
    final r = await CalendarService.registrarResultado(widget.evento['id'], estado: _estado, local: conMarcador ? _local : null, visitante: conMarcador ? _visitante : null);
    if (!mounted) return;
    if (r['exito'] == true) return Navigator.pop(context, true);
    setState(() {
      _guardando = false;
      _error = r['mensaje'].toString();
    });
  }

  Widget _contador(String equipo, int valor, ValueChanged<int> cambio) => Expanded(
        child: Column(children: [
          Text(equipo, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13, color: AppColors.textGray, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            IconButton(onPressed: valor > 0 ? () => cambio(valor - 1) : null, icon: const Icon(Icons.remove_circle_outline), color: AppColors.secondary),
            SizedBox(width: 36, child: Text('$valor', textAlign: TextAlign.center, style: const TextStyle(fontSize: 28, color: AppColors.textWhite, fontWeight: FontWeight.bold))),
            IconButton(onPressed: valor < 99 ? () => cambio(valor + 1) : null, icon: const Icon(Icons.add_circle_outline), color: AppColors.secondary),
          ]),
        ]),
      );

  @override
  Widget build(BuildContext context) {

    final e = widget.evento;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('Registrar resultado', style: TextStyle(fontSize: 18, color: AppColors.textWhite, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          AppDropdown<String>(label: 'Estado del partido', hint: 'Estado', value: _estado, items: {for (final s in estadosPartido) s: s}, onChanged: (v) => setState(() => _estado = v ?? _estado)),
          const SizedBox(height: 20),
          Row(children: [
            _contador((e['equipo_local']?['nombre'] ?? 'Local').toString(), _local, (v) => setState(() => _local = v)),
            _contador((e['equipo_visitante']?['nombre'] ?? 'Visitante').toString(), _visitante, (v) => setState(() => _visitante = v)),
          ]),
          const SizedBox(height: 6),
          const Text('El marcador se guarda si el partido está En vivo o Finalizado. Al finalizar, la tabla de posiciones se actualiza sola.', textAlign: TextAlign.center, style: TextStyle(fontSize: 11, color: AppColors.textGray)),
          if (_error != null) Padding(padding: const EdgeInsets.only(top: 10), child: Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.error, fontSize: 13))),
          const SizedBox(height: 18),
          AppButton(label: 'Guardar', isLoading: _guardando, backgroundColor: AppColors.blue, onPressed: _guardar),
        ]),
      ),
    );
  }
}