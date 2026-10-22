import 'package:flutter/material.dart';
import '../core/app_colors.dart';
import '../core/calendar_utils.dart';
import '../components/admin_widgets.dart';
import '../components/app_dialogs.dart';
import '../components/event_card.dart';
import '../components/month_grid.dart';
import '../services/calendar_service.dart';
import 'event_detail_page.dart';
import 'event_form_page.dart';

/// Pestaña Calendario: mes con puntos en los días que tienen eventos y la lista del día elegido
class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  late DateTime _mes = DateTime(DateTime.now().year, DateTime.now().month);
  DateTime _dia = DateUtils.dateOnly(DateTime.now());
  bool _mios = false;
  final _porDia = <String, List<Map<String, dynamic>>>{};
  bool _cargando = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    final r = await CalendarService.eventos(DateTime(_mes.year, _mes.month, 1), DateTime(_mes.year, _mes.month + 1, 0), mios: _mios);
    if (!mounted) return;
    setState(() {
      _cargando = false;
      if (r['exito'] != true) {
        _error = r['mensaje'].toString();
        return;
      }
      _error = null;
      _porDia.clear();
      for (final e in (r['eventos'] as List).cast<Map<String, dynamic>>()) {
        _porDia.putIfAbsent(e['fecha'].toString().split('T').first, () => []).add(e);
      }
    });
  }

  void _irAMes(DateTime nuevo) {
    final hoy = DateTime.now();
    setState(() {
      _mes = DateTime(nuevo.year, nuevo.month);
      _dia = (nuevo.year == hoy.year && nuevo.month == hoy.month) ? DateUtils.dateOnly(hoy) : DateTime(nuevo.year, nuevo.month, 1);
      _cargando = true;
    });
    _cargar();
  }

  Future<void> _nuevoEvento() async {
    final creado = await Navigator.push<bool>(context, MaterialPageRoute(builder: (_) => EventFormPage(fechaInicial: _dia)));
    if (creado == true && mounted) _cargar();
  }

  Future<void> _abrir(Map<String, dynamic> e) async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => EventDetailPage(eventoId: e['id'] as Object)));
    if (mounted) _cargar();
  }

  @override
  Widget build(BuildContext context) {
    final delDia = _porDia[isoFecha(_dia)] ?? [];
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        backgroundColor: AppColors.bgDark,
        elevation: 0,
        title: const Text('Calendario'),
        actions: [TextButton(onPressed: () => _irAMes(DateTime.now()), child: const Text('Hoy', style: TextStyle(color: AppColors.secondary, fontWeight: FontWeight.bold)))],
      ),
      floatingActionButton: puedeCrearEventos
          ? FloatingActionButton.extended(
              onPressed: _nuevoEvento,
              backgroundColor: AppColors.blue,
              foregroundColor: AppColors.textWhite,
              icon: const Icon(Icons.add),
              label: const Text('Nuevo evento', style: TextStyle(fontWeight: FontWeight.bold)),
            )
          : null,
      body: RefreshIndicator(
        onRefresh: _cargar,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
          children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              IconButton(icon: const Icon(Icons.chevron_left, color: AppColors.textWhite), onPressed: () => _irAMes(DateTime(_mes.year, _mes.month - 1))),
              Text('${nombresMes[_mes.month - 1][0].toUpperCase()}${nombresMes[_mes.month - 1].substring(1)} ${_mes.year}', style: const TextStyle(fontSize: 18, color: AppColors.textWhite, fontWeight: FontWeight.bold)),
              IconButton(icon: const Icon(Icons.chevron_right, color: AppColors.textWhite), onPressed: () => _irAMes(DateTime(_mes.year, _mes.month + 1))),
            ]),
            FiltroChips<bool>(
              opciones: const {'Todos los eventos': false, 'Mis partidos': true},
              valor: _mios,
              onChanged: (v) {
                if (v == true && !requireAuth(context)) return; // "Mis partidos" necesita sesión
                setState(() {
                  _mios = v ?? false;
                  _cargando = true;
                });
                _cargar();
              },
            ),
            const SizedBox(height: 12),
            MonthGrid(mes: _mes, seleccionado: _dia, eventosPorDia: {for (final e in _porDia.entries) e.key: e.value.length}, onSeleccionar: (d) => setState(() => _dia = d)),
            const Divider(color: AppColors.bgCardLight, height: 28),
            Text(fechaLarga(_dia), style: const TextStyle(fontSize: 16, color: AppColors.textWhite, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(delDia.isEmpty ? 'Sin eventos' : '${delDia.length} evento${delDia.length == 1 ? '' : 's'}', style: const TextStyle(fontSize: 12, color: AppColors.textGray)),
            const SizedBox(height: 12),
            if (_cargando)
              const Padding(padding: EdgeInsets.all(32), child: Center(child: CircularProgressIndicator()))
            else if (_error != null)
              Column(children: [
                Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textGray)),
                TextButton(onPressed: () {
                  setState(() => _cargando = true);
                  _cargar();
                }, child: const Text('Reintentar')),
              ])
            else if (delDia.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 28),
                child: Center(child: Text(_mios ? 'No tienes partidos este día' : 'No hay eventos este día', style: const TextStyle(color: AppColors.textGray))),
              )
            else
              for (final e in delDia) EventCard(evento: e, onTap: () => _abrir(e)),
          ],
        ),
      ),
    );
  }
}