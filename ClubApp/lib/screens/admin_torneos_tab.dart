import 'package:flutter/material.dart';
import '../core/app_colors.dart';
import '../components/admin_widgets.dart';
import '../components/tournament_chip.dart';
import '../services/admin_service.dart';
import 'admin_torneo_page.dart';

class AdminTorneosTab extends StatefulWidget {
  const AdminTorneosTab({super.key});

  @override
  State<AdminTorneosTab> createState() => _AdminTorneosTabState();
}

class _AdminTorneosTabState extends State<AdminTorneosTab> with AutomaticKeepAliveClientMixin {
  List<Map<String, dynamic>> _torneos = [];
  String _busqueda = '';
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
    final r = await AdminService.torneos();
    if (!mounted) return;

    setState(() {
      _cargando = false;
      _error = r['exito'] == true ? null : r['mensaje'].toString();
      if (r['exito'] == true) _torneos = (r['torneos'] as List).cast<Map<String, dynamic>>();
    });
  }

  Future<void> _abrir(Map<String, dynamic> t) async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => AdminTorneoPage(torneo: t, estadosExistentes: {for (final x in _torneos) (x['estado'] ?? '').toString()})));
    if (mounted) _cargar();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final q = _busqueda.trim().toLowerCase();
    final lista = _torneos.where((t) => '${t['nombre']} ${t['ciudad'] ?? ''} ${t['deportes']?['nombre'] ?? ''}'.toLowerCase().contains(q)).toList();
    return AdminCuerpo(
      cargando: _cargando,
      error: _error,
      onRefresh: _cargar,
      vacio: 'No hay torneos',
      encabezado: Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: TextField(
          onChanged: (v) => setState(() => _busqueda = v),
          style: const TextStyle(color: AppColors.textWhite),
          decoration: InputDecoration(
            hintText: 'Buscar torneo',
            hintStyle: const TextStyle(color: AppColors.textGray, fontSize: 13),
            prefixIcon: const Icon(Icons.search, color: AppColors.textGray),
            filled: true,

            fillColor: AppColors.bgCard,
            contentPadding: const EdgeInsets.symmetric(vertical: 12),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          ),
        ),
      ),
      hijos: [
        for (final t in lista)
          AdminTarjeta(
            leading: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(color: AppColors.blue, borderRadius: BorderRadius.circular(12)),
              child: const Icon(Icons.emoji_events, color: AppColors.textWhite),
            ),
            titulo: (t['nombre'] ?? '').toString(),
            subtitulo: '${t['deportes']?['nombre'] ?? ''} · ${t['formatos']?['nombre'] ?? ''} · ${'${t['usuarios']?['nombre'] ?? ''} ${t['usuarios']?['apellido'] ?? ''}'.trim()}',
            chips: [
              TournamentChip((t['estado'] ?? 'Sin estado').toString(), color: colorEstado((t['estado'] ?? '').toString())),
              TournamentChip('${t['equipos']}/${t['max_equipos'] ?? '-'} equipos', color: AppColors.primaryLight, icono: Icons.groups),
              TournamentChip('${t['finalizados']}/${t['partidos']} partidos', color: AppColors.secondary, icono: Icons.sports_soccer),
              TournamentChip('${t['goles']} goles', color: AppColors.success),
              if ((t['pendientes'] as num) > 0) TournamentChip('${t['pendientes']} por aprobar', color: AppColors.warning),
            ],
            trailing: const Icon(Icons.chevron_right, color: AppColors.textGray),
            onTap: () => _abrir(t),
          ),
      ],
    );
  }
}