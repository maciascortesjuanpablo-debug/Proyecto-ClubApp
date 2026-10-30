import 'package:flutter/material.dart';
import '../core/app_colors.dart';
import '../core/roles.dart';
import '../components/admin_widgets.dart';
import '../components/app_dialogs.dart';
import '../components/home/load_error.dart';
import '../components/tournament_chip.dart';
import '../models/models.dart';
import '../services/tournament_service.dart';
import 'create_tournament_page.dart';
import 'torneo/torneo_page.dart';

/// Pestaña Torneos. Cambia según el rol:
/// el organizador ve y gestiona SUS torneos (y puede crear); el admin ve todos y puede crear;
/// jugador, entrenador, árbitro e invitados explorar todos los torneos en modo consulta.
class TournamentsPage extends StatefulWidget {
  const TournamentsPage({super.key});

  @override
  State<TournamentsPage> createState() => _TournamentsPageState();
}

class _TournamentsPageState extends State<TournamentsPage> {
  List<Torneo>? _torneos;
  bool _cargando = true;
  String _busqueda = '';
  String? _estado; // null = todos

  RolApp get _rol => RolApp.actual;
  bool get _soloMios => _rol == RolApp.organizador;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    List<Torneo>? lista;
    if (_soloMios) {
      lista = (await TournamentService.gestionables()).dato;
    } else {
      final json = await TournamentService.listar();
      lista = json?.map(Torneo.fromJson).toList();
    }
    if (!mounted) return;
    setState(() {
      _torneos = lista;
      _cargando = false;
    });
  }

  void _aviso(String texto) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(texto)));

  Future<void> _crear() async {
    if (!requireAuth(context)) return;
    final creado = await Navigator.push<bool>(context, MaterialPageRoute(builder: (_) => const CreateTournamentPage()));
    if (!mounted || creado != true) return;
    _aviso('Torneo creado');
    _cargar();
  }

  List<Torneo> get _filtrados {
    final q = _busqueda.trim().toLowerCase();
    return (_torneos ?? []).where((t) {
      if (_estado == 'activo' && t.estado != 'Activo') return false;
      if (_estado == 'cerrado' && !t.cerrado) return false;
      return '${t.nombre} ${t.ciudad ?? ''} ${t.deporte}'.toLowerCase().contains(q);
    }).toList();
  }

  String get _subtitulo => switch (_rol) {
        RolApp.organizador => 'Crea y administra tus campeonatos',
        RolApp.entrenador => 'Encuentra torneos e inscribe a tu equipo',
        RolApp.jugador => 'Sigue los torneos donde juega tu equipo',
        RolApp.arbitro => 'Consulta los torneos y sus partidos',
        _ => 'Encuentra y sigue los campeonatos',
      };

  @override
  Widget build(BuildContext context) {
    final lista = _filtrados;
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      floatingActionButton: _rol.gestionaTorneos
          ? FloatingActionButton.extended(
              onPressed: _crear,
              backgroundColor: AppColors.blue,
              foregroundColor: AppColors.textWhite,
              icon: const Icon(Icons.add),
              label: const Text('Crear torneo', style: TextStyle(fontWeight: FontWeight.bold)),
            )
          : null,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _cargar,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 130),
            children: [
              Text(_soloMios ? 'Mis torneos' : 'Torneos', style: const TextStyle(fontSize: 24, color: AppColors.textWhite, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(_subtitulo, style: const TextStyle(fontSize: 13, color: AppColors.textGray)),
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
              const SizedBox(height: 12),
              FiltroChips<String>(opciones: const {'Todos': null, 'En curso': 'activo', 'Finalizados': 'cerrado'}, valor: _estado, onChanged: (v) => setState(() => _estado = v)),
              const SizedBox(height: 16),
              if (_cargando)
                const Padding(padding: EdgeInsets.all(60), child: Center(child: CircularProgressIndicator()))
              else if (_torneos == null)
                LoadError(onRetry: () {
                  setState(() => _cargando = true);
                  _cargar();
                })
              else if (lista.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(40),
                  child: Center(child: Text(_soloMios && _torneos!.isEmpty ? 'Aún no has creado torneos. Toca "Crear torneo" para empezar.' : 'No hay torneos para mostrar', textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textGray))),
                )
              else
                for (final t in lista) _card(t),
            ],
          ),
        ),
      ),
    );
  }

  Widget _card(Torneo t) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Material(
          color: AppColors.bgCard,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () async {
              await Navigator.push(context, MaterialPageRoute(builder: (_) => TorneoPage(torneoId: t.id, nombre: t.nombre)));
              if (mounted) _cargar();
            },
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
                    Text(t.nombre, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 15, color: AppColors.textWhite, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 2),
                    Text([t.deporte, t.formato].where((e) => e.isNotEmpty).join(' · '), style: const TextStyle(fontSize: 12, color: AppColors.textGray)),
                    const SizedBox(height: 8),
                    Wrap(spacing: 8, runSpacing: 6, children: [
                      TournamentChip(t.estado, color: colorEstado(t.estado)),
                      if (t.ciudad != null) TournamentChip(t.ciudad!, color: AppColors.secondary, icono: Icons.location_on),
                      TournamentChip('Máx. ${t.maxEquipos == 0 ? '-' : t.maxEquipos} equipos', color: AppColors.primaryLight, icono: Icons.groups),
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
