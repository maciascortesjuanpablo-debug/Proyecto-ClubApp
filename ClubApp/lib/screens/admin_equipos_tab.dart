import 'package:flutter/material.dart';
import '../core/app_colors.dart';
import '../components/admin_widgets.dart';
import '../components/tournament_chip.dart';
import '../services/admin_service.dart';
import 'admin_equipo_page.dart';

class AdminEquiposTab extends StatefulWidget {
  const AdminEquiposTab({super.key});

  @override
  State<AdminEquiposTab> createState() => _AdminEquiposTabState();
}

class _AdminEquiposTabState extends State<AdminEquiposTab> with AutomaticKeepAliveClientMixin {
  List<Map<String, dynamic>> _equipos = [];
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
    final r = await AdminService.equipos();
    if (!mounted) return;
    setState(() {
      _cargando = false;
      _error = r['exito'] == true ? null : r['mensaje'].toString();
      if (r['exito'] == true) _equipos = (r['equipos'] as List).cast<Map<String, dynamic>>();
    });
  }

  Future<void> _abrir(Map<String, dynamic> e) async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => AdminEquipoPage(equipo: e)));
    if (mounted) _cargar();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final q = _busqueda.trim().toLowerCase();
    final lista = _equipos.where((e) => (e['nombre'] ?? '').toString().toLowerCase().contains(q)).toList();
    return AdminCuerpo(
      cargando: _cargando,
      error: _error,
      onRefresh: _cargar,
      vacio: 'No hay equipos',
      encabezado: Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: TextField(
          onChanged: (v) => setState(() => _busqueda = v),
          style: const TextStyle(color: AppColors.textWhite),
          decoration: InputDecoration(
            hintText: 'Buscar equipo',
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
        for (final e in lista)
          AdminTarjeta(
            leading: CircleAvatar(
              backgroundColor: AppColors.primary,
              backgroundImage: e['logo_url'] != null ? NetworkImage(e['logo_url'].toString()) : null,
              child: e['logo_url'] != null ? null : const Icon(Icons.groups, color: AppColors.textWhite),
            ),
            titulo: (e['nombre'] ?? '').toString(),
            chips: [
              TournamentChip('${e['jugadores']} jugadores', color: AppColors.secondary, icono: Icons.person),
              TournamentChip('${e['torneos']} torneos', color: AppColors.primaryLight, icono: Icons.emoji_events),
            ],
            trailing: const Icon(Icons.chevron_right, color: AppColors.textGray),
            onTap: () => _abrir(e),
          ),
      ],
    );
  }
}