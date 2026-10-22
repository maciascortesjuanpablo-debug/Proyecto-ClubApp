import 'package:flutter/material.dart';
import '../core/app_colors.dart';
import '../core/perfil_constants.dart';
import '../components/admin_widgets.dart';
import '../components/stat_card.dart';
import '../services/admin_service.dart';

class AdminResumenTab extends StatefulWidget {
  const AdminResumenTab({super.key});

  @override
  State<AdminResumenTab> createState() => _AdminResumenTabState();
}

class _AdminResumenTabState extends State<AdminResumenTab> with AutomaticKeepAliveClientMixin {
  Map<String, dynamic>? _d;
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
    final r = await AdminService.resumen();
    if (!mounted) return;
    setState(() {
      _cargando = false;
      _error = r['exito'] == true ? null : r['mensaje'].toString();
      if (r['exito'] == true) _d = r;
    });
  }

  Widget _fila(StatCard a, StatCard b) => Padding(padding: const EdgeInsets.only(bottom: 12), child: Row(children: [Expanded(child: a), const SizedBox(width: 12), Expanded(child: b)]));

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final d = _d;
    return AdminCuerpo(
      cargando: _cargando,
      error: _error,
      onRefresh: _cargar,
      hijos: d == null ? [] : _contenido(d),
    );
  }

  List<Widget> _contenido(Map<String, dynamic> d) {
    final usuarios = d['usuarios'] as Map<String, dynamic>;
    final torneos = d['torneos'] as Map<String, dynamic>;
    final partidos = d['partidos'] as Map<String, dynamic>;
    final porEstado = (torneos['porEstado'] as Map<String, dynamic>).map((k, v) => MapEntry(k, (v as num).toInt()));
    final porRol = (usuarios['porRol'] as Map<String, dynamic>).map((k, v) => MapEntry(rolesNombre[int.tryParse(k)] ?? k, (v as num).toInt()));
    final pendientes = (d['inscripcionesPendientes'] as num).toInt();

    return [
      _fila(
        StatCard(value: '${usuarios['total']}', label: 'Usuarios', subLabel: '+${usuarios['nuevos7d']} esta semana', color: AppColors.success),
        StatCard(value: '${torneos['total']}', label: 'Torneos', subLabel: '${porEstado['Activo'] ?? 0} activos', color: AppColors.primaryLight),
      ),
      _fila(
        StatCard(value: '${d['equipos']}', label: 'Equipos', subLabel: 'registrados', color: AppColors.secondary),
        StatCard(value: '${partidos['total']}', label: 'Partidos', subLabel: '${partidos['finalizados']} finalizados · ${partidos['enVivo']} en vivo', color: AppColors.success),
      ),
      _fila(
        StatCard(value: '${d['goles']}', label: 'Goles', subLabel: 'en partidos finalizados', color: AppColors.primaryLight),
        StatCard(value: '$pendientes', label: 'Por aprobar', subLabel: pendientes > 0 ? 'inscripciones pendientes' : 'todo al día', color: pendientes > 0 ? AppColors.warning : AppColors.success),
      ),
      Text('${usuarios['activos']} de ${usuarios['total']} usuarios están activos', style: const TextStyle(fontSize: 12, color: AppColors.textGray)),
      AdminBarras(titulo: 'Usuarios por rol', datos: porRol),
      AdminBarras(titulo: 'Torneos por estado', datos: porEstado),
    ];
  }
}