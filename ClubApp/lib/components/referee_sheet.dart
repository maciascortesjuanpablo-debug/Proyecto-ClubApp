import 'package:flutter/material.dart';
import '../core/app_colors.dart';
import '../services/calendar_service.dart';

/// Hoja para asignar y quitar árbitros de un evento (organizador del torneo o admin)
Future<void> mostrarArbitros(BuildContext context, Map<String, dynamic> evento) => showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.bgCard,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _ArbitrosSheet(evento: evento),
    );

class _ArbitrosSheet extends StatefulWidget {
  final Map<String, dynamic> evento;

  const _ArbitrosSheet({required this.evento});

  @override
  State<_ArbitrosSheet> createState() => _ArbitrosSheetState();
}

class _ArbitrosSheetState extends State<_ArbitrosSheet> {
  late final List<Map<String, dynamic>> _asignados = ((widget.evento['arbitros'] as List?) ?? []).cast<Map<String, dynamic>>().toList();
  List<Map<String, dynamic>> _disponibles = [];
  bool _cargando = true;
  String? _mensaje;

  @override
  void initState() {
    super.initState();
    _cargar();

  }

  Future<void> _cargar() async {
    final r = await CalendarService.arbitrosDisponibles();
    if (!mounted) return;
    setState(() {
      _cargando = false;
      if (r['exito'] == true) {
        _disponibles = (r['arbitros'] as List).cast<Map<String, dynamic>>();
      } else {
        _mensaje = r['mensaje'].toString();
      }
    });
  }

  String _nombre(Map<String, dynamic> u) => '${u['nombre'] ?? ''} ${u['apellido'] ?? ''}'.trim();

  Future<void> _asignar(Map<String, dynamic> u) async {
    final r = await CalendarService.asignarArbitro(widget.evento['id'], u['id'] as Object);
    if (!mounted) return;
    setState(() {
      _mensaje = r['exito'] == true ? null : r['mensaje'].toString();
      if (r['exito'] == true) {
        final fila = r['arbitro'] as Map<String, dynamic>;
        _asignados.add({'id': fila['id'], 'rol_arbitraje': fila['rol_arbitraje'], 'usuarios': u});
      }
    });
  }

  Future<void> _quitar(Map<String, dynamic> a) async {
    final r = await CalendarService.quitarArbitro(widget.evento['id'], a['id'] as Object);
    if (!mounted) return;

    setState(() {
      _mensaje = r['exito'] == true ? null : r['mensaje'].toString();
      if (r['exito'] == true) _asignados.remove(a);
    });
  }

  Widget _titulo(String t) => Padding(padding: const EdgeInsets.only(top: 14, bottom: 8), child: Text(t, style: const TextStyle(fontSize: 14, color: AppColors.textWhite, fontWeight: FontWeight.bold)));

  @override
  Widget build(BuildContext context) {
    final idsAsignados = _asignados.map((a) => a['usuarios']?['id']?.toString()).toSet();
    final libres = _disponibles.where((u) => !idsAsignados.contains(u['id'].toString())).toList();
    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.75),
      child: ListView(padding: const EdgeInsets.fromLTRB(20, 20, 20, 28), shrinkWrap: true, children: [
        const Text('Árbitros del evento', style: TextStyle(fontSize: 18, color: AppColors.textWhite, fontWeight: FontWeight.bold)),
        if (_mensaje != null) Padding(padding: const EdgeInsets.only(top: 8), child: Text(_mensaje!, style: const TextStyle(color: AppColors.error, fontSize: 13))),
        _titulo('Asignados (${_asignados.length})'),
        if (_asignados.isEmpty) const Text('Todavía no hay árbitros asignados', style: TextStyle(color: AppColors.textGray, fontSize: 13)),
        for (final a in _asignados)
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const CircleAvatar(backgroundColor: AppColors.blue, child: Icon(Icons.sports, color: AppColors.textWhite, size: 20)),
            title: Text(_nombre((a['usuarios'] as Map<String, dynamic>?) ?? {}), style: const TextStyle(color: AppColors.textWhite)),
            subtitle: Text((a['rol_arbitraje'] ?? 'Principal').toString(), style: const TextStyle(color: AppColors.textGray, fontSize: 12)),
            trailing: IconButton(tooltip: 'Quitar', icon: const Icon(Icons.remove_circle_outline, color: AppColors.error), onPressed: () => _quitar(a)),
          ),
        _titulo('Disponibles'),
        if (_cargando) const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator())),
        if (!_cargando && libres.isEmpty) const Text('No hay más árbitros registrados', style: TextStyle(color: AppColors.textGray, fontSize: 13)),
        for (final u in libres)
          ListTile(

            contentPadding: EdgeInsets.zero,
            leading: const CircleAvatar(backgroundColor: AppColors.bgCardLight, child: Icon(Icons.person, color: AppColors.textWhite, size: 20)),
            title: Text(_nombre(u), style: const TextStyle(color: AppColors.textWhite)),
            trailing: TextButton(onPressed: () => _asignar(u), child: const Text('Asignar', style: TextStyle(color: AppColors.secondary, fontWeight: FontWeight.bold))),
          ),
      ]),
    );
  }
}