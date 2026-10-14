import 'package:flutter/material.dart';
import '../core/app_colors.dart';
import '../components/app_dialogs.dart';
import '../components/home/load_error.dart';
import '../components/tournament_chip.dart';
import '../services/auth_service.dart';
import '../services/tournament_service.dart';
import 'create_tournament_page.dart';
import 'tournament_detail_page.dart';

class TournamentsPage extends StatefulWidget {
  const TournamentsPage({super.key});

  @override
  State<TournamentsPage> createState() => _TournamentsPageState();
}

class _TournamentsPageState extends State<TournamentsPage> {
  List<Map<String, dynamic>>? _torneos;
  bool _cargando = true;
  String _busqueda = '';

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    final torneos = await TournamentService.listar();
    if (!mounted) return;
    setState(() {
      _torneos = torneos;
      _cargando = false;
    });
  }

  void _aviso(String texto) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(texto)));

  Future<void> _crear() async {
    if (!requireAuth(context)) return;
    final rol = AuthService.usuario?['rol_id']; // 4 = Organizador, 6 = Admin
    if (rol != 4 && rol != 6) return _aviso('Solo los organizadores pueden crear torneos');

    final creado = await Navigator.push<bool>(context, MaterialPageRoute(builder: (_) => const CreateTournamentPage()));
    if (!mounted || creado != true) return;
    _aviso('Torneo creado');
    _cargar();
  }

  List<Map<String, dynamic>> get _filtrados {
    final q = _busqueda.trim().toLowerCase();
    return (_torneos ?? []).where((t) => '${t['nombre']} ${t['ciudad'] ?? ''} ${t['deportes']?['nombre'] ?? ''}'.toLowerCase().contains(q)).toList();
  }

  @override
  Widget build(BuildContext context) {
    final lista = _filtrados;
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _crear,
        backgroundColor: AppColors.blue,
        foregroundColor: AppColors.textWhite,
        icon: const Icon(Icons.add),
        label: const Text('Crear torneo', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _cargar,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
            children: [
              const Text('Torneos', style: TextStyle(fontSize: 24, color: AppColors.textWhite, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              const Text('Encuentra y organiza tus campeonatos', style: TextStyle(fontSize: 13, color: AppColors.textGray)),
              const SizedBox(height: 16),
              TextField(
                onChanged: (v) => setState(() => _busqueda = v),
                style: const TextStyle(color: AppColors.textWhite),
                decoration: InputDecoration(
                  hintText: 'Buscar por nombre, deporte o ciudad',
                  hintStyle: const TextStyle(color: AppColors.textGray, fontSize: 13),
                  prefixIcon: const Icon(Icons.search, color: AppColors.textGray),
                  filled: true,
                  fillColor: AppColors.bgCard,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 16),
              if (_cargando)
                const Padding(padding: EdgeInsets.all(60), child: Center(child: CircularProgressIndicator()))
              else if (_torneos == null)
                LoadError(onRetry: () {
                  setState(() => _cargando = true);
                  _cargar();
                })
              else if (lista.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(40),
                  child: Center(child: Text('No hay torneos para mostrar', style: TextStyle(color: AppColors.textGray))),
                )
              else
                for (final t in lista) _card(t),
            ],
          ),
        ),
      ),
    );
  }

  Widget _card(Map<String, dynamic> t) {
    final estado = (t['estado'] ?? 'Sin estado').toString();
    final ciudad = t['ciudad']?.toString();
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => TournamentDetailPage(torneo: t))),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(color: AppColors.blue, borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.emoji_events, color: AppColors.textWhite),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text((t['nombre'] ?? '').toString(),
                      maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 15, color: AppColors.textWhite, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 2),
                  Text('${t['deportes']?['nombre'] ?? ''} · ${t['formatos']?['nombre'] ?? ''}', style: const TextStyle(fontSize: 12, color: AppColors.textGray)),
                  const SizedBox(height: 8),
                  Wrap(spacing: 8, runSpacing: 6, children: [
                    TournamentChip(estado, color: colorEstado(estado)),
                    if (ciudad != null && ciudad.isNotEmpty) TournamentChip(ciudad, color: AppColors.secondary, icono: Icons.location_on),
                    TournamentChip('Máx. ${t['max_equipos'] ?? '-'} equipos', color: AppColors.primaryLight, icono: Icons.groups),
                  ]),
                ]),
              ),
              const Icon(Icons.chevron_right, color: AppColors.textGray),
            ]),
          ),
        ),
      ),
    );
  }
}