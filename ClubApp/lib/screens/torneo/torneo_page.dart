import 'package:flutter/material.dart';
import '../../components/admin_widgets.dart';
import '../../core/app_colors.dart';
import '../../core/roles.dart';
import '../../models/models.dart';
import '../../services/auth_service.dart';
import '../../services/team_service.dart';
import '../../services/tournament_service.dart';
import 'editar_torneo_page.dart';
import 'torneo_calendario_tab.dart';
import 'torneo_equipos_tab.dart';
import 'torneo_fixture_tab.dart';
import 'torneo_partidos_tab.dart';
import 'torneo_posiciones_tab.dart';
import 'torneo_resumen_tab.dart';

/// Detalle de un torneo, común a todos los roles. Las pestañas cambian según quién lo mira:
/// todos ven Resumen, Posiciones, Partidos y Equipos; el organizador dueño (o el admin) además
/// tiene el Fixture automático y el Calendario para programar partidos, gestiona las inscripciones
/// y, desde el menú ⋮, edita, finaliza, cancela, reabre o elimina el torneo.
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

  void _aviso(String t) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t)));

  Future<void> _editar() async {
    final r = _resumen!;
    final guardado = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => EditarTorneoPage(torneo: r.torneo, tienePartidos: r.partidosTotal > 0, equiposAceptados: r.equiposAceptados)),
    );
    if (guardado == true && mounted) _cargar();
  }

  /// Finalizar o cancelar. Si quedan partidos sin jugar se pide confirmación y se cancelan; con un partido en vivo no se permite.
  Future<void> _cerrar(String estado) async {
    final r = _resumen!;
    final accion = estado == 'Finalizado' ? 'Finalizar' : 'Cancelar';
    if (r.enVivo > 0) return _aviso('Hay ${r.enVivo} partido(s) en vivo. Termínalos antes de ${accion.toLowerCase()} el torneo.');
    final sinJugar = r.programados + r.aplazados;
    final ok = await confirmar(
      context,
      titulo: '$accion torneo',
      mensaje: 'El torneo quedará ${estado == 'Finalizado' ? 'finalizado' : 'cancelado'}: no admitirá más inscripciones ni partidos nuevos, y se avisará a los equipos y árbitros.'
          '${sinJugar > 0 ? '\n\nHay $sinJugar partido(s) sin jugar: se cancelarán.' : ''}',
      accion: accion,
      peligro: estado == 'Cancelado',
    );
    if (!ok || !mounted) return;
    final res = await TournamentService.cambiarEstado(widget.torneoId, estado, forzar: sinJugar > 0);
    if (!mounted) return;
    _aviso(res['mensaje'].toString());
    if (res['exito'] == true) _cargar();
  }

  Future<void> _reabrir() async {
    final ok = await confirmar(context, titulo: 'Reabrir torneo', mensaje: 'El torneo vuelve a estar activo y admite inscripciones y partidos. Los partidos que se cancelaron al cerrarlo siguen cancelados.', accion: 'Reabrir');
    if (!ok || !mounted) return;
    final res = await TournamentService.cambiarEstado(widget.torneoId, 'Activo');
    if (!mounted) return;
    _aviso(res['mensaje'].toString());
    if (res['exito'] == true) _cargar();
  }

  Future<void> _eliminar() async {
    final r = _resumen!;
    if (r.finalizados > 0 || r.enVivo > 0) {
      return _aviso('Ya tiene partidos jugados o en juego: no se puede eliminar. Cancélalo o finalízalo para conservar el historial.');
    }
    final ok = await confirmar(
      context,
      titulo: 'Eliminar torneo',
      mensaje: 'Se borrará "${r.torneo.nombre}" con sus ${r.partidosTotal} partido(s), las inscripciones de ${r.equiposAceptados + r.equiposPendientes} equipo(s) y la tabla de posiciones. Se avisará a los participantes.\n\nNo se puede deshacer.',
      accion: 'Eliminar',
      peligro: true,
    );
    if (!ok || !mounted) return;
    final res = await TournamentService.eliminar(widget.torneoId);
    if (!mounted) return;
    _aviso(res['exito'] == true ? 'Torneo eliminado' : res['mensaje'].toString());
    if (res['exito'] == true) Navigator.pop(context);
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
      if (gestor) ('Fixture', TorneoFixtureTab(key: ValueKey('fix$_version'), torneo: r.torneo, onCambio: _cargar)),
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
          actions: [
            if (gestor)
              PopupMenuButton<String>(
                tooltip: 'Gestionar torneo',
                onSelected: (v) => switch (v) {
                  'editar' => _editar(),
                  'finalizar' => _cerrar('Finalizado'),
                  'cancelar' => _cerrar('Cancelado'),
                  'reabrir' => _reabrir(),
                  _ => _eliminar(),
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(value: 'editar', child: Text('Editar datos del torneo')),
                  if (!r.torneo.cerrado) const PopupMenuItem(value: 'finalizar', child: Text('Finalizar torneo')),
                  if (!r.torneo.cerrado) const PopupMenuItem(value: 'cancelar', child: Text('Cancelar torneo')),
                  if (r.torneo.cerrado) const PopupMenuItem(value: 'reabrir', child: Text('Reabrir torneo')),
                  const PopupMenuItem(value: 'eliminar', child: Text('Eliminar torneo', style: TextStyle(color: AppColors.error))),
                ],
              ),
          ],
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