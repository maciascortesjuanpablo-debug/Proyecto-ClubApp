import 'package:flutter/material.dart';
import '../core/app_colors.dart';
import '../components/admin_widgets.dart';
import '../services/admin_service.dart';

class AdminInscripcionesTab extends StatefulWidget {
  const AdminInscripcionesTab({super.key});

  @override
  State<AdminInscripcionesTab> createState() => _AdminInscripcionesTabState();
}

class _AdminInscripcionesTabState extends State<AdminInscripcionesTab> with AutomaticKeepAliveClientMixin {
  List<Map<String, dynamic>> _items = [];
  String _estado = 'Pendiente';
  String? _error;
  bool _cargando = true;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    final r = await AdminService.inscripciones(_estado);
    if (!mounted) return;
    setState(() {
      _cargando = false;
      _error = r['exito'] == true ? null : r['mensaje'].toString();
      if (r['exito'] == true) _items = (r['inscripciones'] as List).cast<Map<String, dynamic>>();
    });
  }

  Future<void> _resolver(Map<String, dynamic> i, String estado) async {
    final r = await AdminService.resolverInscripcion(i['id'], estado);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(r['exito'] == true ? 'Inscripción: $estado' : r['mensaje'].toString())));
    if (r['exito'] == true) _cargar();
  }

  String _fecha(dynamic iso) {
    final d = DateTime.tryParse(iso?.toString() ?? '')?.toLocal();
    return d == null ? '' : '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return AdminCuerpo(
      cargando: _cargando,
      error: _error,
      onRefresh: _cargar,
      vacio: _estado == 'Pendiente' ? 'No hay inscripciones por aprobar 🎉' : 'No hay inscripciones en este estado',
      encabezado: Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: FiltroChips<String>(
          opciones: const {'Pendientes': 'Pendiente', 'Aceptadas': 'Aceptado', 'Rechazadas': 'Rechazado'},
          valor: _estado,
          onChanged: (v) {
            setState(() {
              _estado = v ?? 'Pendiente';
              _cargando = true;
            });
            _cargar();
          },
        ),
      ),
      hijos: [
        for (final i in _items)
          AdminTarjeta(
            leading: const CircleAvatar(backgroundColor: AppColors.primary, child: Icon(Icons.groups, color: AppColors.textWhite)),
            titulo: (i['equipos']?['nombre'] ?? 'Equipo').toString(),
            subtitulo: '${i['torneo']} · ${_fecha(i['fecha_inscripcion'])}',
            trailing: Row(mainAxisSize: MainAxisSize.min, children: [
              if (_estado != 'Aceptado') IconButton(tooltip: 'Aprobar', icon: const Icon(Icons.check_circle_outline, color: AppColors.success), onPressed: () => _resolver(i, 'Aceptado')),
              if (_estado != 'Rechazado') IconButton(tooltip: _estado == 'Aceptado' ? 'Revocar' : 'Rechazar', icon: const Icon(Icons.cancel_outlined, color: AppColors.error), onPressed: () => _resolver(i, 'Rechazado')),
            ]),
          ),
      ],
    );
  }
}