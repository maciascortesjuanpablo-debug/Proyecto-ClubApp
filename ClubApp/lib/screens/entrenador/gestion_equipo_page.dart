import 'package:flutter/material.dart';
import '../../components/admin_widgets.dart';
import '../../components/editar_jugador.dart';
import '../../components/equipo_widgets.dart';
import '../../components/partido_tile.dart';
import '../../components/role_guard.dart';
import '../../components/tournament_chip.dart';
import '../../components/ui_kit.dart';
import '../../core/app_colors.dart';
import '../../core/roles.dart';
import '../../models/models.dart';
import '../../services/panel_service.dart';
import '../../services/resultado.dart';
import '../../services/team_service.dart';
import '../../services/tournament_service.dart';
import '../event_detail_page.dart';
import '../torneo/torneo_page.dart';
import 'alineacion_tab.dart';
import 'equipo_form_page.dart';

/// Gestión de un equipo (solo ENTRENADOR): ficha, alineación en el campo, plantilla, partidos y torneos.
/// Desde aquí se invita a jugadores y se solicita unirse a un torneo.
class GestionEquipoPage extends StatefulWidget {
  final Equipo equipo;
  const GestionEquipoPage({super.key, required this.equipo});

  @override
  State<GestionEquipoPage> createState() => _GestionEquipoPageState();
}

class _GestionEquipoPageState extends State<GestionEquipoPage> {
  late Equipo _equipo = widget.equipo;
  int _jugadores = 0;
  int _version = 0; // al cambiar, las pestañas vuelven a pedir sus datos

  @override
  void initState() {
    super.initState();
    _refrescarFicha();
  }

  /// Ficha actualizada del equipo y cantidad de jugadores en la plantilla
  Future<void> _refrescarFicha() async {
    final r = await Future.wait([TeamService.detalle(_equipo.id), TeamService.plantilla(_equipo.id)]);
    if (!mounted) return;
    final ficha = r[0] as Resultado<Equipo>;
    final plantilla = r[1] as Resultado<List<JugadorPlantilla>>;
    setState(() {
      if (ficha.dato != null) _equipo = ficha.dato!;
      _jugadores = plantilla.dato?.length ?? _jugadores;
    });
  }

  void _cambio() {
    setState(() => _version++);
    _refrescarFicha();
  }

  void _aviso(String t) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t)));

  Future<void> _editar() async {
    final guardado = await Navigator.push<bool>(context, MaterialPageRoute(builder: (_) => EquipoFormPage(equipo: _equipo)));
    if (guardado == true && mounted) _cambio();
  }

  Future<void> _eliminar() async {
    final ok = await confirmar(context, titulo: 'Eliminar equipo', mensaje: 'Se eliminará "${_equipo.nombre}" con su plantilla. Esta acción no se puede deshacer.', accion: 'Eliminar', peligro: true);
    if (!ok) return;
    final r = await TeamService.eliminar(_equipo.id);
    if (!mounted) return;
    if (r['exito'] != true) {
      _aviso(r['mensaje'].toString());
      return;
    }
    Navigator.pop(context);
  }

  Future<void> _invitar() async {
    final enviada = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.bgCard,
      builder: (_) => _BuscarJugadorSheet(equipoId: _equipo.id),
    );
    if (enviada == true && mounted) _aviso('Invitación enviada');
  }

  /// Elige un torneo disponible y envía la solicitud de inscripción del equipo
  Future<void> _solicitarTorneo() async {
    final panel = await PanelService.entrenador();
    final json = await TournamentService.listar();
    if (!mounted) return;
    final mio = panel.dato?.equipos.where((x) => '${x.id}' == '${_equipo.id}');
    final ya = (mio == null || mio.isEmpty ? <Inscripcion>[] : mio.first.inscripciones).map((i) => '${i.torneo?.id}').toSet();
    final libres = (json ?? []).map(Torneo.fromJson).where((t) => !t.cerrado && !ya.contains('${t.id}')).toList();
    if (libres.isEmpty) {
      _aviso('No hay torneos disponibles para solicitar');
      return;
    }
    final t = await showModalBottomSheet<Torneo>(
      context: context,
      backgroundColor: AppColors.bgCard,
      builder: (c) => SafeArea(
        child: ListView(shrinkWrap: true, children: [
          const Padding(padding: EdgeInsets.all(16), child: Text('Solicitar unirse a un torneo', style: TextStyle(fontSize: 16, color: AppColors.textWhite, fontWeight: FontWeight.bold))),
          for (final t in libres)
            ListTile(
              leading: const Icon(Icons.emoji_events, color: AppColors.secondary),
              title: Text(t.nombre, style: const TextStyle(color: AppColors.textWhite)),
              subtitle: Text('${t.deporte} · ${t.estado}${t.ciudad != null ? ' · ${t.ciudad}' : ''}', style: const TextStyle(color: AppColors.textGray, fontSize: 12)),
              onTap: () => Navigator.pop(c, t),
            ),
        ]),
      ),
    );
    if (t == null) return;
    final r = await TeamService.inscribirEnTorneo(_equipo.id, t.id);
    if (!mounted) return;
    _aviso(r['exito'] == true ? 'Solicitud enviada: el organizador debe aceptarla' : r['mensaje'].toString());
    if (r['exito'] == true) _cambio();
  }

  @override
  Widget build(BuildContext context) {
    final e = _equipo;
    return RoleGuard(
      roles: const {RolApp.entrenador},
      child: DefaultTabController(
        length: 4,
        child: Scaffold(
          backgroundColor: AppColors.bgDark,
          appBar: AppBar(
            backgroundColor: AppColors.bgDark,
            elevation: 0,
            title: Text(e.nombre, maxLines: 1, overflow: TextOverflow.ellipsis),
            actions: [
              PopupMenuButton<String>(
                onSelected: (v) => v == 'editar' ? _editar() : _eliminar(),
                itemBuilder: (_) => const [PopupMenuItem(value: 'editar', child: Text('Editar equipo')), PopupMenuItem(value: 'eliminar', child: Text('Eliminar equipo'))],
              ),
            ],
          ),
          body: Column(children: [
            _cabecera(e),
            const TabBar(
              indicatorColor: AppColors.secondary,
              labelColor: AppColors.secondary,
              unselectedLabelColor: AppColors.textGray,
              tabs: [Tab(text: 'Alineación'), Tab(text: 'Plantilla'), Tab(text: 'Partidos'), Tab(text: 'Torneos')],
            ),
            Expanded(
              child: TabBarView(children: [
                AlineacionTab(key: ValueKey('ali$_version${e.formacion}'), equipo: e),
                _PlantillaTab(key: ValueKey('pla$_version'), equipo: e, onCambio: _cambio),
                _PartidosTab(key: ValueKey('par$_version'), equipo: e),
                _TorneosTab(key: ValueKey('tor$_version'), equipo: e, onSolicitar: _solicitarTorneo),
              ]),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _cabecera(Equipo e) {
    final cupo = e.maxJugadores;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(gradient: LinearGradient(colors: [e.color, e.color.withValues(alpha: 0.4)], begin: Alignment.topLeft, end: Alignment.bottomRight), borderRadius: BorderRadius.circular(20)),
      child: Column(children: [
        Row(children: [
          EquipoAvatar(nombre: e.nombre, logoUrl: e.logoUrl, tamano: 58),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(e.nombre, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 19, color: Colors.white, fontWeight: FontWeight.bold)),
              if (e.eslogan != null) Text('“${e.eslogan}”', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12.5, color: Colors.white70, fontStyle: FontStyle.italic)),
              const SizedBox(height: 4),
              Text([if (e.formato != null) e.formato!, if (e.formacion != null) e.formacion!, if (e.ciudad != null) e.ciudad!].join(' · '), style: const TextStyle(fontSize: 12, color: Colors.white70)),
            ]),
          ),
          Column(children: [
            Text('$_jugadores${cupo != null ? '/$cupo' : ''}', style: const TextStyle(fontSize: 20, color: Colors.white, fontWeight: FontWeight.bold)),
            const Text('jugadores', style: TextStyle(fontSize: 10.5, color: Colors.white70)),
          ]),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: _boton(Icons.person_add_alt_1, 'Invitar jugador', _invitar)),
          const SizedBox(width: 10),
          Expanded(child: _boton(Icons.how_to_reg, 'Unirse a torneo', _solicitarTorneo)),
        ]),
      ]),
    );
  }

  Widget _boton(IconData icono, String texto, VoidCallback onTap) => Material(
        color: Colors.black26,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 11),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(icono, size: 18, color: Colors.white), const SizedBox(width: 8), Text(texto, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13))]),
          ),
        ),
      );
}

/* ------------------------------ Plantilla ------------------------------ */
class _PlantillaTab extends StatelessWidget {
  final Equipo equipo;
  final VoidCallback onCambio;
  const _PlantillaTab({super.key, required this.equipo, required this.onCambio});

  Future<void> _editar(BuildContext context, JugadorPlantilla j) async {
    if (await editarJugadorEquipo(context, equipo.id, j)) onCambio();
  }

  Future<void> _quitar(BuildContext context, JugadorPlantilla j) async {
    if (j.usuarioId == null) return;
    final ok = await confirmar(context, titulo: 'Quitar jugador', mensaje: '${j.nombreCompleto} saldrá de la plantilla.', accion: 'Quitar', peligro: true);
    if (!ok || !context.mounted) return;
    final r = await TeamService.quitarJugador(equipo.id, j.usuarioId!);
    if (!context.mounted) return;
    if (r['exito'] != true) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(r['mensaje'].toString())));
      return;
    }
    onCambio();
  }

  @override
  Widget build(BuildContext context) => CargadorLista<(List<JugadorPlantilla>, List<MiembroStaff>)>(
        cargar: () async {
          final r = await Future.wait([TeamService.plantilla(equipo.id), TeamService.staff(equipo.id)]);
          final p = r[0] as Resultado<List<JugadorPlantilla>>;
          final s = r[1] as Resultado<List<MiembroStaff>>;
          return p.ok ? Resultado.ok((p.dato!, s.dato ?? <MiembroStaff>[])) : Resultado.fallo(p.error!);
        },
        construir: (context, datos, _) => [
          SeccionTitulo('Jugadores (${datos.$1.length}${equipo.maxJugadores != null ? ' de ${equipo.maxJugadores}' : ''})'),
          PlantillaLista(
            jugadores: datos.$1,
            accion: (j) => PopupMenuButton<String>(
              onSelected: (v) => v == 'editar' ? _editar(context, j) : _quitar(context, j),
              itemBuilder: (_) => const [PopupMenuItem(value: 'editar', child: Text('Editar posición / dorsal')), PopupMenuItem(value: 'quitar', child: Text('Quitar del equipo'))],
            ),
          ),
          if (datos.$2.isNotEmpty) ...[const SeccionTitulo('Cuerpo técnico'), StaffLista(datos.$2)],
        ],
      );
}

class _BuscarJugadorSheet extends StatefulWidget {
  final Object equipoId;
  const _BuscarJugadorSheet({required this.equipoId});

  @override
  State<_BuscarJugadorSheet> createState() => _BuscarJugadorSheetState();
}

class _BuscarJugadorSheetState extends State<_BuscarJugadorSheet> {
  final _q = TextEditingController();
  List<JugadorBuscado> _resultados = [];
  bool _buscando = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _buscar();
  }

  Future<void> _buscar() async {
    setState(() => _buscando = true);
    final r = await TeamService.buscarJugadores(_q.text.trim(), widget.equipoId);
    if (!mounted) return;
    setState(() {
      _buscando = false;
      _error = r.error;
      _resultados = r.dato ?? [];
    });
  }

  Future<void> _invitar(JugadorBuscado j) async {
    final pos = TextEditingController(text: j.posicion ?? '');
    final ok = await showDialog<bool>(
      context: context,
      builder: (d) => AlertDialog(
        backgroundColor: AppColors.bgCard,
        title: Text('Invitar a ${j.nombreCompleto}', style: const TextStyle(color: AppColors.textWhite)),
        content: TextField(controller: pos, style: const TextStyle(color: AppColors.textWhite), decoration: const InputDecoration(labelText: 'Posición propuesta (opcional)')),
        actions: [TextButton(onPressed: () => Navigator.pop(d, false), child: const Text('Cancelar')), TextButton(onPressed: () => Navigator.pop(d, true), child: const Text('Invitar'))],
      ),
    );
    if (ok != true) return;
    final r = await TeamService.invitar(widget.equipoId, j.id, pos.text.trim());
    if (!mounted) return;
    if (r['exito'] != true) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(r['mensaje'].toString())));
      return;
    }
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.75,
          child: Column(children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _q,
                onSubmitted: (_) => _buscar(),
                style: const TextStyle(color: AppColors.textWhite),
                decoration: InputDecoration(hintText: 'Buscar jugador por nombre', prefixIcon: const Icon(Icons.search), suffixIcon: IconButton(icon: const Icon(Icons.arrow_forward), onPressed: _buscar)),
              ),
            ),
            if (_buscando) const LinearProgressIndicator(),
            Expanded(
              child: _error != null
                  ? Center(child: Text(_error!, style: const TextStyle(color: AppColors.textGray)))
                  : _resultados.isEmpty
                      ? const EstadoVacio(icono: Icons.person_search, mensaje: 'No se encontraron jugadores')
                      : ListView(children: [
                          for (final j in _resultados)
                            ListTile(
                              leading: CircleAvatar(backgroundColor: AppColors.bgCardLight, child: Text(inicialesDe(j.nombre, j.apellido), style: const TextStyle(color: AppColors.textWhite))),
                              title: Text(j.nombreCompleto, style: const TextStyle(color: AppColors.textWhite)),
                              subtitle: Text([if (j.posicion != null) j.posicion!, if (j.nivel != null) j.nivel!, if (j.ciudad != null) j.ciudad!].join(' · '), style: const TextStyle(color: AppColors.textGray, fontSize: 12)),
                              trailing: const Icon(Icons.person_add_alt_1, color: AppColors.secondary),
                              onTap: () => _invitar(j),
                            ),
                        ]),
            ),
          ]),
        ),
      );
}

/* ------------------------------- Partidos ------------------------------- */
class _PartidosTab extends StatelessWidget {
  final Equipo equipo;
  const _PartidosTab({super.key, required this.equipo});

  @override
  Widget build(BuildContext context) => CargadorLista<({List<Partido> partidos, BalanceEquipo balance})>(
        cargar: () => TeamService.partidos(equipo.id),
        construir: (context, d, recargar) {
          void abrir(Partido p) => Navigator.push(context, MaterialPageRoute(builder: (_) => EventDetailPage(eventoId: p.id)));
          final proximos = d.partidos.where((p) => p.esPartido && !p.finalizado && p.estado != 'Cancelado').toList();
          final jugados = d.partidos.where((p) => p.finalizado).toList().reversed.toList();
          return [
            FormaReciente(partidos: d.partidos, equipoId: equipo.id),
            const SeccionTitulo('Balance'),
            BalanceCard(d.balance),
            const SeccionTitulo('Próximos'),
            if (proximos.isEmpty) const EstadoVacio(icono: Icons.event_busy_outlined, mensaje: 'Sin partidos programados'),
            for (final p in proximos) PartidoTile(partido: p, mostrarFecha: true, onTap: () => abrir(p)),
            if (jugados.isNotEmpty) ...[const SeccionTitulo('Resultados'), for (final p in jugados) PartidoTile(partido: p, mostrarFecha: true, destacarEquipoId: equipo.id, onTap: () => abrir(p))],
          ];
        },
      );
}

/* -------------------------------- Torneos -------------------------------- */
class _TorneosTab extends StatelessWidget {
  final Equipo equipo;
  final VoidCallback onSolicitar;
  const _TorneosTab({super.key, required this.equipo, required this.onSolicitar});

  Future<Resultado<List<Inscripcion>>> _cargar() async {
    final r = await PanelService.entrenador();
    if (!r.ok) return Resultado.fallo(r.error!);
    final e = r.dato!.equipos.where((x) => '${x.id}' == '${equipo.id}');
    return Resultado.ok(e.isEmpty ? <Inscripcion>[] : e.first.inscripciones);
  }

  @override
  Widget build(BuildContext context) => CargadorLista<List<Inscripcion>>(
        cargar: _cargar,
        construir: (context, lista, _) => [
          FilledButton.icon(onPressed: onSolicitar, icon: const Icon(Icons.how_to_reg), label: const Text('Solicitar unirse a un torneo')),
          const SeccionTitulo('Inscripciones del equipo'),
          if (lista.isEmpty) const EstadoVacio(icono: Icons.emoji_events_outlined, mensaje: 'Este equipo aún no está inscrito en ningún torneo'),
          for (final i in lista)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: TarjetaBase(
                onTap: i.torneo == null ? null : () => Navigator.push(context, MaterialPageRoute(builder: (_) => TorneoPage(torneoId: i.torneo!.id, nombre: i.torneo!.nombre))),
                child: Row(children: [
                  const Icon(Icons.emoji_events, color: AppColors.secondary),
                  const SizedBox(width: 12),
                  Expanded(child: Text(i.torneo?.nombre ?? 'Torneo', style: const TextStyle(color: AppColors.textWhite, fontWeight: FontWeight.w600))),
                  TournamentChip(i.estado, color: switch (i.estado) { 'Aceptado' => AppColors.success, 'Rechazado' => AppColors.error, _ => AppColors.warning }),
                ]),
              ),
            ),
        ],
      );
}