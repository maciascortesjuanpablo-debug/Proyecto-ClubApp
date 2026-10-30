import 'package:flutter/material.dart';
import '../core/app_colors.dart';
import '../core/calendar_utils.dart';
import '../core/roles.dart';
import '../components/admin_widgets.dart';
import '../components/charts.dart';
import '../components/ui_kit.dart';
import '../models/models.dart';
import '../services/admin_service.dart';

/// Resumen del panel de administración con indicadores y gráficos
class AdminResumenTab extends StatefulWidget {
  const AdminResumenTab({super.key});

  @override
  State<AdminResumenTab> createState() => _AdminResumenTabState();
}

class _AdminResumenTabState extends State<AdminResumenTab> with AutomaticKeepAliveClientMixin {
  AdminResumen? _d;
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
      if (r['exito'] == true) _d = AdminResumen.fromJson(r);
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final d = _d;
    return AdminCuerpo(cargando: _cargando, error: _error, onRefresh: _cargar, hijos: d == null ? [] : _contenido(d));
  }

  static const _coloresEstadoPartido = {
    'Programado': AppColors.primaryLight,
    'En vivo': AppColors.success,
    'Finalizado': AppColors.textGray,
    'Aplazado': AppColors.warning,
    'Cancelado': AppColors.error,
  };

  List<SegmentoDonut> _segmentos(Map<String, int> datos, Map<String, Color> colores) => [
        for (final e in datos.entries)
          if (e.value > 0) SegmentoDonut(e.key, e.value, colores[e.key] ?? AppColors.bgCardLight),
      ];

  Widget _tarjetaDonut(String titulo, List<SegmentoDonut> segmentos, String centro, String sub) => Padding(
        padding: const EdgeInsets.only(top: 16),
        child: TarjetaBase(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(titulo, style: const TextStyle(fontSize: 14, color: AppColors.textWhite, fontWeight: FontWeight.bold)),
            const SizedBox(height: 14),
            if (segmentos.isEmpty)
              const Text('Sin datos', style: TextStyle(color: AppColors.textGray, fontSize: 12))
            else
              Row(children: [DonutChart(segmentos: segmentos, centro: centro, subcentro: sub, tamano: 120), const SizedBox(width: 20), Expanded(child: LeyendaChart(segmentos))]),
          ]),
        ),
      );

  List<Widget> _contenido(AdminResumen d) {
    final pendientes = d.inscripcionesPendientes;
    final porRol = _segmentos(
      {for (final e in d.usuariosPorRol.entries) RolApp.deId(e.key).nombre: e.value},
      {for (final r in RolApp.values) r.nombre: r.color},
    );
    final meses = [
      for (final m in d.usuariosPorMes)
        BarraDato(() {
          final n = int.tryParse(m.mes.split('-').last) ?? 1;
          final nombre = nombresMes[(n - 1).clamp(0, 11)];
          return '${nombre[0].toUpperCase()}${nombre.substring(1, 3)}';
        }(), m.total),
    ];
    final inscripciones = _segmentos(d.inscripcionesPorEstado, {'Aceptado': AppColors.success, 'Pendiente': AppColors.warning, 'Rechazado': AppColors.error});

    return [
      KpiGrid([
        KpiTile(icono: Icons.people_alt_rounded, valor: '${d.usuarios}', etiqueta: 'Usuarios', color: AppColors.success, detalle: '+${d.usuariosNuevos7d} esta semana'),
        KpiTile(icono: Icons.emoji_events_rounded, valor: '${d.torneos}', etiqueta: 'Torneos', color: AppColors.primaryLight, detalle: '${d.torneosPorEstado['Activo'] ?? 0} activos'),
        KpiTile(icono: Icons.groups_rounded, valor: '${d.equipos}', etiqueta: 'Equipos', color: AppColors.secondary, detalle: 'registrados'),
        KpiTile(icono: Icons.sports_soccer, valor: '${d.partidos}', etiqueta: 'Partidos', color: AppColors.orange, detalle: '${d.partidosFinalizados} jugados · ${d.partidosEnVivo} en vivo'),
        KpiTile(icono: Icons.sports_score, valor: '${d.goles}', etiqueta: 'Goles', color: AppColors.primaryLight, detalle: d.partidosFinalizados == 0 ? null : '${d.promedioGoles.toStringAsFixed(1)} por partido'),
        KpiTile(icono: Icons.how_to_reg, valor: '$pendientes', etiqueta: 'Por aprobar', color: pendientes > 0 ? AppColors.warning : AppColors.success, detalle: pendientes > 0 ? 'inscripciones pendientes' : 'todo al día'),
      ]),
      Padding(
        padding: const EdgeInsets.only(top: 16),
        child: TarjetaBase(
          child: Row(children: [
            AnilloProgreso(valor: d.porcentajeActivos, texto: '${(d.porcentajeActivos * 100).round()}%', color: AppColors.success, tamano: 70),
            const SizedBox(width: 16),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Usuarios activos', style: TextStyle(fontSize: 14, color: AppColors.textWhite, fontWeight: FontWeight.bold)),
              Text('${d.usuariosActivos} de ${d.usuarios} cuentas', style: const TextStyle(fontSize: 12, color: AppColors.textGray)),
            ])),
          ]),
        ),
      ),
      _tarjetaDonut('Usuarios por rol', porRol, '${d.usuarios}', 'usuarios'),
      Padding(
        padding: const EdgeInsets.only(top: 16),
        child: TarjetaBase(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Registros de los últimos 6 meses', style: TextStyle(fontSize: 14, color: AppColors.textWhite, fontWeight: FontWeight.bold)),
            const SizedBox(height: 14),
            BarrasVerticales(datos: meses, color: AppColors.success),
          ]),
        ),
      ),
      _tarjetaDonut('Estado de los partidos', _segmentos(d.partidosPorEstado, _coloresEstadoPartido), '${d.partidos}', 'partidos'),
      _tarjetaDonut('Inscripciones de equipos', inscripciones, '${d.inscripcionesPorEstado.values.fold<int>(0, (a, b) => a + b)}', 'solicitudes'),
      AdminBarras(titulo: 'Torneos por estado', datos: d.torneosPorEstado),
      AdminBarras(titulo: 'Goles por torneo (top 5)', datos: {for (final t in d.golesPorTorneo) t.nombre: t.goles}),
    ];
  }
}
