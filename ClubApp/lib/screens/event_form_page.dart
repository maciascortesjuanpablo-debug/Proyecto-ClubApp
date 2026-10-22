import 'package:flutter/material.dart';
import '../core/app_colors.dart';
import '../core/calendar_utils.dart';
import '../components/app_button.dart';
import '../components/app_dropdown.dart';
import '../services/calendar_service.dart';

/// Crear o editar un evento. Para editar se pasa `evento`; para crear, opcionalmente la fecha preseleccionada.
class EventFormPage extends StatefulWidget {
  final Map<String, dynamic>? evento;
  final DateTime? fechaInicial;

  const EventFormPage({super.key, this.evento, this.fechaInicial});

  @override
  State<EventFormPage> createState() => _EventFormPageState();
}

class _EventFormPageState extends State<EventFormPage> {
  bool get _edicion => widget.evento != null;

  Map<Object, String> _torneos = {};
  Map<Object, String> _equipos = {};
  Map<Object, String> _sedes = {};
  Object? _torneoId;
  Object? _localId;
  Object? _visitanteId;
  Object? _sedeId;
  String _tipo = 'Partido';
  DateTime? _fecha;
  TimeOfDay? _hora;
  bool _cargando = true;
  bool _guardando = false;

  @override
  void initState() {
    super.initState();
    _iniciar();
  }

  Future<void> _iniciar() async {
    final e = widget.evento;
    if (e != null) {
      _torneoId = e['torneo_id'] as Object?;
      _tipo = (e['tipo'] ?? 'Partido').toString();
      _fecha = parseFecha(e['fecha']);
      final h = horaCorta(e['hora']).split(':');
      if (h.length == 2) _hora = TimeOfDay(hour: int.tryParse(h[0]) ?? 0, minute: int.tryParse(h[1]) ?? 0);
      _localId = e['equipo_local_id'] as Object?;
      _visitanteId = e['equipo_visitante_id'] as Object?;
      _sedeId = e['lugar_id'] as Object?;
      if (_torneoId != null) _torneos = {_torneoId!: (e['torneo']?['nombre'] ?? 'Torneo').toString()};
    } else {
      _fecha = widget.fechaInicial;
    }

    final r = await Future.wait([CalendarService.torneosGestionables(), CalendarService.sedes()]);
    if (!mounted) return;
    setState(() {
      if (!_edicion && r[0]['exito'] == true) {
        _torneos = {for (final t in (r[0]['datos'] as List).cast<Map<String, dynamic>>()) t['id'] as Object: t['nombre'].toString()};
      }
      if (r[1]['exito'] == true) _sedes = {for (final s in (r[1]['datos'] as List).cast<Map<String, dynamic>>()) s['id'] as Object: s['nombre'].toString()};
      _cargando = false;
    });
    if (_torneoId != null) await _cargarEquipos();
  }

  /// Equipos aceptados en el torneo elegido (los únicos que pueden jugar en él)
  Future<void> _cargarEquipos() async {
    final r = await CalendarService.equiposAceptados(_torneoId!);
    if (!mounted) return;
    setState(() {
      _equipos = r['exito'] == true ? {for (final t in (r['equipos'] as List).cast<Map<String, dynamic>>()) t['id'] as Object: t['nombre'].toString()} : {};
      if (!_equipos.containsKey(_localId)) _localId = null;
      if (!_equipos.containsKey(_visitanteId)) _visitanteId = null;
    });
  }

  void _aviso(String texto) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(texto)));

  String _hhmm(TimeOfDay h) => '${h.hour.toString().padLeft(2, '0')}:${h.minute.toString().padLeft(2, '0')}';

  Future<void> _elegirFecha() async {
    final f = await showDatePicker(context: context, initialDate: _fecha ?? DateTime.now(), firstDate: DateTime(2020), lastDate: DateTime(2100));
    if (f != null) setState(() => _fecha = f);
  }

  Future<void> _elegirHora() async {
    final h = await showTimePicker(context: context, initialTime: _hora ?? const TimeOfDay(hour: 16, minute: 0));
    if (h != null) setState(() => _hora = h);
  }

  Future<void> _nuevaSede() async {
    final nombre = TextEditingController();
    final direccion = TextEditingController();
    final ciudad = TextEditingController();
    InputDecoration deco(String hint) => InputDecoration(hintText: hint, hintStyle: const TextStyle(color: AppColors.textGray));
    final ok = await showDialog<bool>(
      context: context,
      builder: (d) => AlertDialog(
        backgroundColor: AppColors.bgCard,
        title: const Text('Nueva sede', style: TextStyle(color: AppColors.textWhite)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: nombre, autofocus: true, style: const TextStyle(color: AppColors.textWhite), decoration: deco('Nombre de la cancha')),
          TextField(controller: direccion, style: const TextStyle(color: AppColors.textWhite), decoration: deco('Dirección (opcional)')),
          TextField(controller: ciudad, style: const TextStyle(color: AppColors.textWhite), decoration: deco('Ciudad (opcional)')),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(d, false), child: const Text('Cancelar')),
          TextButton(onPressed: () => Navigator.pop(d, true), child: const Text('Guardar')),
        ],
      ),
    );
    if (ok != true || nombre.text.trim().isEmpty) return;
    final r = await CalendarService.crearSede(nombre: nombre.text.trim(), direccion: direccion.text.trim(), ciudad: ciudad.text.trim());
    if (!mounted) return;
    if (r['exito'] != true) return _aviso(r['mensaje'].toString());
    final sede = r['sede'] as Map<String, dynamic>;
    setState(() {
      _sedes = {..._sedes, sede['id'] as Object: sede['nombre'].toString()};
      _sedeId = sede['id'] as Object;
    });
  }

  Future<void> _guardar() async {
    final partido = _tipo == 'Partido';
    if (!_edicion && _torneoId == null) return _aviso('Elige el torneo');
    if (_fecha == null || _hora == null) return _aviso('Elige la fecha y la hora');
    if (partido && (_localId == null || _visitanteId == null)) return _aviso('Elige los dos equipos');
    if (partido && _localId.toString() == _visitanteId.toString()) return _aviso('Los equipos deben ser distintos');

    setState(() => _guardando = true);
    final datos = <String, dynamic>{
      'tipo': _tipo,
      'fecha': isoFecha(_fecha!),
      'hora': _hhmm(_hora!),
      'lugar_id': _sedeId,
      if (partido) ...{'equipo_local_id': _localId, 'equipo_visitante_id': _visitanteId} else if (_edicion) ...{'equipo_local_id': null, 'equipo_visitante_id': null},
    };
    final r = _edicion ? await CalendarService.actualizarEvento(widget.evento!['id'], datos) : await CalendarService.crearEvento({'torneo_id': _torneoId, ...datos});
    if (!mounted) return;
    if (r['exito'] == true) return Navigator.pop(context, true);
    setState(() => _guardando = false);
    _aviso(r['mensaje'].toString()); // p. ej. "Esa sede ya está ocupada a esa hora"
  }

  Widget _etiqueta(String t) => Padding(padding: const EdgeInsets.only(bottom: 10), child: Text(t, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textWhite)));

  Widget _selector(String etiqueta, IconData icono, String valor, VoidCallback onTap) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _etiqueta(etiqueta),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(color: AppColors.bgCard, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.bgCardLight)),
            child: Row(children: [Icon(icono, color: AppColors.secondary, size: 20), const SizedBox(width: 12), Text(valor, style: const TextStyle(color: AppColors.textWhite, fontSize: 14))]),
          ),
        ),
      ]);

  @override
  Widget build(BuildContext context) {
    final partido = _tipo == 'Partido';
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(backgroundColor: AppColors.bgDark, elevation: 0, title: Text(_edicion ? 'Editar evento' : 'Nuevo evento')),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(children: [
                  if (_edicion)
                    _selector('Torneo', Icons.emoji_events_outlined, _torneos.values.firstOrNull ?? '-', () {})
                  else if (_torneos.isEmpty)
                    const Text('No tienes torneos donde crear eventos. Crea un torneo primero.', textAlign: TextAlign.center, style: TextStyle(color: AppColors.textGray))
                  else
                    AppDropdown<Object>(
                      label: 'Torneo',
                      hint: 'Selecciona el torneo',
                      value: _torneos.containsKey(_torneoId) ? _torneoId : null,
                      items: _torneos,
                      onChanged: (v) {
                        setState(() => _torneoId = v);
                        _cargarEquipos();
                      },
                    ),
                  const SizedBox(height: 16),
                  AppDropdown<String>(label: 'Tipo de evento', hint: 'Tipo', value: _tipo, items: {for (final t in {...tiposEvento, _tipo}) t: t}, onChanged: (v) => setState(() => _tipo = v ?? _tipo)),
                  const SizedBox(height: 16),
                  Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Expanded(child: _selector('Fecha', Icons.event, _fecha == null ? 'Elegir' : '${_fecha!.day}/${_fecha!.month}/${_fecha!.year}', _elegirFecha)),
                    const SizedBox(width: 12),
                    Expanded(child: _selector('Hora', Icons.access_time, _hora == null ? 'Elegir' : _hhmm(_hora!), _elegirHora)),
                  ]),
                  if (partido) ...[
                    const SizedBox(height: 16),
                    AppDropdown<Object>(label: 'Equipo local', hint: _torneoId == null ? 'Elige primero el torneo' : 'Selecciona el equipo', value: _equipos.containsKey(_localId) ? _localId : null, items: _equipos, onChanged: (v) => setState(() => _localId = v)),
                    const SizedBox(height: 16),
                    AppDropdown<Object>(label: 'Equipo visitante', hint: _torneoId == null ? 'Elige primero el torneo' : 'Selecciona el equipo', value: _equipos.containsKey(_visitanteId) ? _visitanteId : null, items: _equipos, onChanged: (v) => setState(() => _visitanteId = v)),
                    if (_torneoId != null && _equipos.length < 2)
                      const Padding(padding: EdgeInsets.only(top: 8), child: Text('Este torneo necesita al menos 2 equipos aceptados para programar partidos.', style: TextStyle(fontSize: 12, color: AppColors.warning))),
                  ],
                  const SizedBox(height: 16),
                  AppDropdown<Object>(label: 'Sede', hint: 'Sin definir', value: _sedes.containsKey(_sedeId) ? _sedeId : null, items: _sedes, onChanged: (v) => setState(() => _sedeId = v)),
                  Align(alignment: Alignment.centerRight, child: TextButton.icon(onPressed: _nuevaSede, icon: const Icon(Icons.add, size: 18), label: const Text('Nueva sede'))),
                  const SizedBox(height: 16),
                  AppButton(label: _edicion ? 'Guardar cambios' : 'Crear evento', isLoading: _guardando, backgroundColor: AppColors.blue, onPressed: _guardar),
                ]),
              ),
            ),
    );
  }
}