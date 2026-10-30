import 'package:flutter/material.dart';
import '../../components/admin_widgets.dart';
import '../../components/equipo_widgets.dart';
import '../../components/partido_tile.dart';
import '../../components/tournament_chip.dart';
import '../../components/ui_kit.dart';
import '../../core/app_colors.dart';
import '../../core/roles.dart';
import '../../components/role_guard.dart';
import '../../models/models.dart';
import '../../services/panel_service.dart';
import '../../services/resultado.dart';
import '../../services/team_service.dart';
import '../../services/tournament_service.dart';
import '../event_detail_page.dart';
import '../torneo/torneo_page.dart';

/// Gestión de un equipo (solo ENTRENADOR): plantilla e invitaciones, partidos y torneos
class GestionEquipoPage extends StatefulWidget {
  final Equipo equipo;
  const GestionEquipoPage({super.key, required this.equipo});

  @override
  State<GestionEquipoPage> createState() => _GestionEquipoPageState();
}

class _GestionEquipoPageState extends State<GestionEquipoPage> {
  late String _nombre = widget.equipo.nombre;

  void _aviso(String t) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t)));

  Future<void> _renombrar() async {
    final c = TextEditingController(text: _nombre);
    final nuevo = await showDialog<String>(
      context: context,
      builder: (d) => AlertDialog(
        backgroundColor: AppColors.bgCard,
        title: const Text('Renombrar equipo', style: TextStyle(color: AppColors.textWhite)),
        content: TextField(controller: c, maxLength: 80, style: const TextStyle(color: AppColors.textWhite)),
        actions: [TextButton(onPressed: () => Navigator.pop(d), child: const Text('Cancelar')), TextButton(onPressed: () => Navigator.pop(d, c.text.trim()), child: const Text('Guardar'))],
      ),
    );
    if (nuevo == null || nuevo.isEmpty || nuevo == _nombre) return;
    final r = await TeamService.renombrar(widget.equipo.id, nuevo);
    if (!mounted) return;
    if (r['exito'] != true) return _aviso(r['mensaje'].toString());
    setState(() => _nombre = nuevo);
  }

  Future<void> _eliminar() async {
    final ok = await confirmar(context, titulo: 'Eliminar equipo', mensaje: 'Se eliminará "$_nombre" con su plantilla. Esta acción no se puede deshacer.', accion: 'Eliminar', peligro: true);
    if (!ok) return;
    final r = await TeamService.eliminar(widget.equipo.id);
    if (!mounted) return;
    if (r['exito'] != true) return _aviso(r['mensaje'].toString());
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) => RoleGuard(
        roles: const {RolApp.entrenador},
        child: DefaultTabController(
          length: 3,
          child: Scaffold(
            backgroundColor: AppColors.bgDark,
            appBar: AppBar(
              backgroundColor: AppColors.bgDark,
              elevation: 0,
              title: Text(_nombre, maxLines: 1, overflow: TextOverflow.ellipsis),
              actions: [
                PopupMenuButton<String>(
                  onSelected: (v) => v == 'renombrar' ? _renombrar() : _eliminar(),
                  itemBuilder: (_) => const [PopupMenuItem(value: 'renombrar', child: Text('Renombrar')), PopupMenuItem(value: 'eliminar', child: Text('Eliminar equipo'))],
                ),
              ],
              bottom: const TabBar(indicatorColor: AppColors.secondary, labelColor: AppColors.secondary, unselectedLabelColor: AppColors.textGray, tabs: [Tab(text: 'Plantilla'), Tab(text: 'Partidos'), Tab(text: 'Torneos')]),
            ),
            body: TabBarView(children: [_PlantillaTab(equipo: widget.equipo), _PartidosTab(equipo: widget.equipo), _TorneosTab(equipo: widget.equipo)]),
          ),
        ),
      );
}

/* ------------------------------ Plantilla ------------------------------ */
class _PlantillaTab extends StatefulWidget {
  final Equipo equipo;
  const _PlantillaTab({required this.equipo});

  @override
  State<_PlantillaTab> createState() => _PlantillaTabState();
}

class _PlantillaTabState extends State<_PlantillaTab> {
  int _version = 0;

  void _aviso(String t) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t)));

  Future<void> _editar(JugadorPlantilla j) async {
    final dorsal = TextEditingController(text: j.dorsal?.toString() ?? '');
    final posicion = TextEditingController(text: j.posicion == 'Sin asignar' ? '' : j.posicion);
    var titular = j.esTitular;
    final guardar = await showDialog<bool>(
      context: context,
      builder: (d) => StatefulBuilder(
        builder: (c, setS) => AlertDialog(
          backgroundColor: AppColors.bgCard,
          title: Text(j.nombreCompleto, style: const TextStyle(color: AppColors.textWhite)),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(controller: posicion, style: const TextStyle(color: AppColors.textWhite), decoration: const InputDecoration(labelText: 'Posición')),
            TextField(controller: dorsal, keyboardType: TextInputType.number, style: const TextStyle(color: AppColors.textWhite), decoration: const InputDecoration(labelText: 'Dorsal')),
            SwitchListTile(contentPadding: EdgeInsets.zero, title: const Text('Titular', style: TextStyle(color: AppColors.textWhite)), value: titular, onChanged: (v) => setS(() => titular = v)),
          ]),
          actions: [TextButton(onPressed: () => Navigator.pop(d, false), child: const Text('Cancelar')), TextButton(onPressed: () => Navigator.pop(d, true), child: const Text('Guardar'))],
        ),
      ),
    );
    if (guardar != true || j.usuarioId == null) return;
    final r = await TeamService.actualizarJugador(widget.equipo.id, j.usuarioId!, {
      if (posicion.text.trim().isNotEmpty) 'posicion': posicion.text.trim(),
      if (int.tryParse(dorsal.text.trim()) != null) 'dorsal': int.parse(dorsal.text.trim()),
      'es_titular': titular,
    });
    if (!mounted) return;
    if (r['exito'] != true) return _aviso(r['mensaje'].toString());
    setState(() => _version++);
  }

  Future<void> _quitar(JugadorPlantilla j) async {
    if (j.usuarioId == null) return;
    final ok = await confirmar(context, titulo: 'Quitar jugador', mensaje: '${j.nombreCompleto} saldrá de la plantilla.', accion: 'Quitar', peligro: true);
    if (!ok) return;
    final r = await TeamService.quitarJugador(widget.equipo.id, j.usuarioId!);
    if (!mounted) return;
    if (r['exito'] != true) return _aviso(r['mensaje'].toString());
    setState(() => _version++);
  }

  Future<void> _invitar() async {
    final enviada = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.bgCard,
      builder: (_) => _BuscarJugadorSheet(equipoId: widget.equipo.id),
    );
    if (enviada == true && mounted) _aviso('Invitación enviada');
  }

  @override
  Widget build(BuildContext context) => CargadorLista<(List<JugadorPlantilla>, List<MiembroStaff>)>(
        key: ValueKey(_version),
        cargar: () async {
          final r = await Future.wait([TeamService.plantilla(widget.equipo.id), TeamService.staff(widget.equipo.id)]);
          final p = r[0] as Resultado<List<JugadorPlantilla>>;
          final s = r[1] as Resultado<List<MiembroStaff>>;
          return p.ok ? Resultado.ok((p.dato!, s.dato ?? <MiembroStaff>[])) : Resultado.fallo(p.error!);
        },
        construir: (context, datos, _) => [
          FilledButton.icon(onPressed: _invitar, icon: const Icon(Icons.person_add_alt_1), label: const Text('Invitar jugador')),
          SeccionTitulo('Jugadores (${datos.$1.length})'),
          PlantillaLista(
            jugadores: datos.$1,
            accion: (j) => PopupMenuButton<String>(
              onSelected: (v) => v == 'editar' ? _editar(j) : _quitar(j),
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
  const _PartidosTab({required this.equipo});

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
class _TorneosTab extends StatefulWidget {
  final Equipo equipo;
  const _TorneosTab({required this.equipo});

  @override
  State<_TorneosTab> createState() => _TorneosTabState();
}

class _TorneosTabState extends State<_TorneosTab> {
  int _version = 0;

  Future<Resultado<List<Inscripcion>>> _cargar() async {
    final r = await PanelService.entrenador();
    if (!r.ok) return Resultado.fallo(r.error!);
    final e = r.dato!.equipos.where((x) => '${x.id}' == '${widget.equipo.id}');
    return Resultado.ok(e.isEmpty ? <Inscripcion>[] : e.first.inscripciones);
  }

  Future<void> _inscribir(List<Inscripcion> actuales) async {
    final json = await TournamentService.listar();
    if (!mounted) return;
    final ya = actuales.map((i) => '${i.torneo?.id}').toSet();
    final libres = (json ?? []).map(Torneo.fromJson).where((t) => !t.cerrado && !ya.contains('${t.id}')).toList();
    if (libres.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No hay torneos disponibles para inscribirse')));
      return;
    }
    final t = await showModalBottomSheet<Torneo>(
      context: context,
      backgroundColor: AppColors.bgCard,
      builder: (c) => SafeArea(
        child: ListView(shrinkWrap: true, children: [
          const Padding(padding: EdgeInsets.all(16), child: Text('Inscribir en un torneo', style: TextStyle(fontSize: 16, color: AppColors.textWhite, fontWeight: FontWeight.bold))),
          for (final t in libres) ListTile(leading: const Icon(Icons.emoji_events, color: AppColors.secondary), title: Text(t.nombre, style: const TextStyle(color: AppColors.textWhite)), subtitle: Text('${t.deporte} · ${t.estado}', style: const TextStyle(color: AppColors.textGray, fontSize: 12)), onTap: () => Navigator.pop(c, t)),
        ]),
      ),
    );
    if (t == null) return;
    final r = await TeamService.inscribirEnTorneo(widget.equipo.id, t.id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(r['exito'] == true ? 'Solicitud enviada: el organizador debe aceptarla' : r['mensaje'].toString())));
    setState(() => _version++);
  }

  @override
  Widget build(BuildContext context) => CargadorLista<List<Inscripcion>>(
        key: ValueKey(_version),
        cargar: _cargar,
        construir: (context, lista, _) => [
          FilledButton.icon(onPressed: () => _inscribir(lista), icon: const Icon(Icons.how_to_reg), label: const Text('Inscribir en un torneo')),
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
