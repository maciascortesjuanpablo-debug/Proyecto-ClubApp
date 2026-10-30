import 'package:flutter/material.dart';
import '../../core/app_colors.dart';
import '../../core/roles.dart';
import '../../models/models.dart';
import '../../services/auth_service.dart';
import '../../services/team_service.dart';
import '../../services/tournament_service.dart';
import 'torneo_calendario_tab.dart';
import 'torneo_equipos_tab.dart';
import 'torneo_partidos_tab.dart';
import 'torneo_posiciones_tab.dart';
import 'torneo_resumen_tab.dart';

/// Detalle de un torneo, común a todos los roles. Las pestañas cambian según quién lo mira:
/// todos ven Resumen, Posiciones, Partidos y Equipos; el organizador dueño (o el admin) además
/// tiene el Calendario para programar partidos y gestiona las inscripciones.
class TorneoPage extends StatefulWidget {
  final Object torneoId;
  final String? nombre;
  const TorneoPage({super.key, required this.torneoId, this.nombre});

  @override
  State<TorneoPage> createState() => _TorneoPageState();
}

class _TorneoPageState extends State<TorneoPage> {
  ResumenTorneo? _resumen;
  String? _error;
  bool _cargando = true;
  Set<String> _mios = {}; // ids de mis equipos (jugador o entrenador) para resaltarlos
  int _version = 0; // cambia al recargar para que las pestañas vuelvan a pedir sus datos

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    final rol = RolApp.actual;
    final r = await TournamentService.resumen(widget.torneoId);
    Set<String> mios = _mios;
    if (rol == RolApp.jugador || rol == RolApp.entrenador) {
      final eq = await TeamService.mios();
      if (eq.ok) mios = eq.dato!.map((e) => '${e.id}').toSet();
    }
    if (!mounted) return;
    setState(() {
      _cargando = false;
      _resumen = r.dato;
      _error = r.error;
      _mios = mios;
      _version++;
    });
  }

  bool get _esGestor {
    final t = _resumen?.torneo;
    if (t == null) return false;
    final rol = RolApp.actual;
    return rol == RolApp.admin || (rol == RolApp.organizador && '${t.organizadorId}' == '${AuthService.usuario?['id']}');
  }

  @override
  Widget build(BuildContext context) {
    final titulo = _resumen?.torneo.nombre ?? widget.nombre ?? 'Torneo';
    if (_cargando || _resumen == null) {
      return Scaffold(
        backgroundColor: AppColors.bgDark,
        appBar: AppBar(backgroundColor: AppColors.bgDark, elevation: 0, title: Text(titulo)),
        body: _cargando
            ? const Center(child: CircularProgressIndicator())
            : Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                Text(_error ?? 'No se pudo cargar el torneo', style: const TextStyle(color: AppColors.textGray)),
                const SizedBox(height: 12),
                OutlinedButton(onPressed: () { setState(() => _cargando = true); _cargar(); }, child: const Text('Reintentar')),
              ])),
      );
    }
    final r = _resumen!;
    final gestor = _esGestor;
    final tabs = <(String, Widget)>[
      ('Resumen', TorneoResumenTab(resumen: r, onRecargar: _cargar)),
      ('Posiciones', TorneoPosicionesTab(key: ValueKey('pos$_version'), torneoId: widget.torneoId, mios: _mios)),
      ('Partidos', TorneoPartidosTab(key: ValueKey('par$_version'), torneoId: widget.torneoId, mios: _mios)),
      ('Equipos', TorneoEquiposTab(key: ValueKey('eq$_version'), torneo: r.torneo, esGestor: gestor, mios: _mios, onCambio: _cargar)),
      if (gestor) ('Calendario', TorneoCalendarioTab(key: ValueKey('cal$_version'), torneo: r.torneo, onCambio: _cargar)),
    ];
    return DefaultTabController(
      length: tabs.length,
      child: Scaffold(
        backgroundColor: AppColors.bgDark,
        appBar: AppBar(
          backgroundColor: AppColors.bgDark,
          elevation: 0,
          title: Text(titulo, maxLines: 1, overflow: TextOverflow.ellipsis),
          bottom: TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            indicatorColor: AppColors.secondary,
            labelColor: AppColors.secondary,
            unselectedLabelColor: AppColors.textGray,
            tabs: [for (final t in tabs) Tab(text: t.$1)],
          ),
        ),
        body: TabBarView(children: [for (final t in tabs) t.$2]),
      ),
    );
  }
}
