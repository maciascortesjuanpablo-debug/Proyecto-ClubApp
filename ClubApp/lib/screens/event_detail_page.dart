import 'package:flutter/material.dart';
import '../core/app_colors.dart';
import '../core/calendar_utils.dart';
import '../components/admin_widgets.dart';
import '../components/estadisticas_partido_card.dart';
import '../components/referee_sheet.dart';
import '../components/result_sheet.dart';
import '../components/tournament_chip.dart';
import '../core/roles.dart';
import '../services/calendar_service.dart';
import '../services/team_service.dart';
import 'estadisticas_partido_page.dart';
import 'event_form_page.dart';

/// Detalle de un evento. Las acciones dependen del rol: el organizador del torneo (o admin) lo edita y gestiona
/// árbitros; también el árbitro asignado puede registrar el resultado.
class EventDetailPage extends StatefulWidget {
  final Object eventoId;

  const EventDetailPage({super.key, required this.eventoId});

  @override
  State<EventDetailPage> createState() => _EventDetailPageState();
}

class _EventDetailPageState extends State<EventDetailPage> {
  Map<String, dynamic>? _e;
  String? _error;
  bool _cargando = true;
  Set<String> _misEquipos = {}; // para el entrenador: sus equipos (solo puede registrar estadísticas del suyo)
  int _version = 0; // al cambiar, la tarjeta de estadísticas vuelve a pedir sus datos

  @override
  void initState() {
    super.initState();
    _cargar();
  }


  Future<void> _cargar() async {
    final r = await CalendarService.evento(widget.eventoId);
    Set<String> mios = _misEquipos;
    if (RolApp.actual == RolApp.entrenador) {
      final eq = await TeamService.mios();
      if (eq.ok) mios = eq.dato!.map((x) => '${x.id}').toSet();
    }
    if (!mounted) return;
    setState(() {
      _cargando = false;
      _misEquipos = mios;
      _version++;
      _error = r['exito'] == true ? null : r['mensaje'].toString();
      if (r['exito'] == true) _e = r;
    });
  }

  /// Equipos de este partido cuyas estadísticas puede registrar quien mira: organizador, admin y árbitro asignado, ambos; el entrenador, el suyo
  Set<String> _equiposEditables(Map<String, dynamic> e) {
    final ids = [e['equipo_local_id'], e['equipo_visitante_id']].where((x) => x != null).map((x) => '$x').toSet();
    if (puedeGestionarEvento(e) || soyArbitroDe(e)) return ids;
    return ids.where(_misEquipos.contains).toSet();
  }

  Future<void> _estadisticas(Set<String> editables) async {
    final guardado = await Navigator.push<bool>(context, MaterialPageRoute(builder: (_) => EstadisticasPartidoPage(eventoId: widget.eventoId, evento: _e!, equiposEditables: editables)));
    if (guardado == true && mounted) _cargar();
  }

  void _aviso(String texto) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(texto)));

  Future<void> _resultado() async {
    if (await mostrarResultado(context, _e!) && mounted) _cargar();
  }

  Future<void> _editar() async {
    final guardado = await Navigator.push<bool>(context, MaterialPageRoute(builder: (_) => EventFormPage(evento: _e)));
    if (guardado == true && mounted) _cargar();
  }

  Future<void> _arbitros() async {
    await mostrarArbitros(context, _e!);
    if (mounted) _cargar();
  }

  Future<void> _eliminar() async {
    final ok = await confirmar(context, titulo: 'Eliminar evento', mensaje: 'Se borrará el evento con sus árbitros y estadísticas. Si ya tenía resultado, la tabla de posiciones se recalcula.', accion: 'Eliminar', peligro: true);
    if (!ok || !mounted) return;
    final r = await CalendarService.eliminarEvento(widget.eventoId);
    if (!mounted) return;
    _aviso(r['exito'] == true ? 'Evento eliminado' : r['mensaje'].toString());

    if (r['exito'] == true) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: AppColors.bgDark,
        appBar: AppBar(backgroundColor: AppColors.bgDark, elevation: 0, title: const Text('Evento')),
        body: _cargando
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(child: Text(_error!, style: const TextStyle(color: AppColors.textGray)))
                : RefreshIndicator(onRefresh: _cargar, child: ListView(physics: const AlwaysScrollableScrollPhysics(), padding: const EdgeInsets.all(20), children: _contenido(_e!))),
      );

  List<Widget> _contenido(Map<String, dynamic> e) {
    final estado = (e['estado'] ?? 'Programado').toString();
    final partido = e['tipo'] == 'Partido';
    final fecha = parseFecha(e['fecha']);
    final gestiona = puedeGestionarEvento(e);
    final puedeResultado = partido && (gestiona || soyArbitroDe(e));
    final arbitros = ((e['arbitros'] as List?) ?? []).cast<Map<String, dynamic>>();
    final sede = e['sedes_canchas'] as Map<String, dynamic>?;
    final jugado = partido && (estado == 'En vivo' || estado == 'Finalizado');
    final editables = jugado ? _equiposEditables(e) : <String>{};

    return [
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: AppColors.blue, borderRadius: BorderRadius.circular(16)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Wrap(spacing: 6, children: [TournamentChip(estado, color: AppColors.textWhite), TournamentChip((e['tipo'] ?? 'Evento').toString(), color: AppColors.textWhite)]),
          const SizedBox(height: 12),
          Text((e['torneo']?['nombre'] ?? '').toString(), style: const TextStyle(fontSize: 20, color: AppColors.textWhite, fontWeight: FontWeight.bold)),

          const SizedBox(height: 6),
          Text('${fecha == null ? '' : fechaLarga(fecha)} · ${horaCorta(e['hora'])}', style: TextStyle(fontSize: 13, color: AppColors.textWhite.withValues(alpha: 0.75))),
        ]),
      ),
      if (partido) ...[const SizedBox(height: 16), _marcador(e)],
      const SizedBox(height: 16),
      _fila(Icons.location_on_outlined, 'Sede', sede == null ? 'Sin definir' : [sede['nombre'], sede['direccion'], sede['ciudad']].where((x) => x != null && x.toString().isNotEmpty).join(' · ')),
      _fila(Icons.sports_outlined, 'Árbitros', arbitros.isEmpty ? 'Sin asignar' : arbitros.map((a) => '${a['usuarios']?['nombre'] ?? ''} ${a['usuarios']?['apellido'] ?? ''}'.trim()).join(', ')),
      const SizedBox(height: 12),
      if (puedeResultado) _accion(Icons.scoreboard_outlined, 'Registrar resultado', _resultado),
      if (editables.isNotEmpty) _accion(Icons.bar_chart_rounded, 'Registrar estadísticas de jugadores', () => _estadisticas(editables)),
      if (jugado) ...[const SizedBox(height: 4), EstadisticasPartidoCard(key: ValueKey('est$_version'), eventoId: widget.eventoId), const SizedBox(height: 14)],
      if (gestiona) ...[
        _accion(Icons.edit_outlined, 'Editar evento', _editar),
        _accion(Icons.sports, 'Gestionar árbitros', _arbitros),
        _accion(Icons.delete_outline, 'Eliminar evento', _eliminar, color: AppColors.error),
      ],
    ];
  }

  Widget _equipo(Map<String, dynamic>? eq) {
    final nombre = (eq?['nombre'] ?? 'Por definir').toString();
    final logo = eq?['logo_url']?.toString();
    return Expanded(
      child: Column(children: [
        CircleAvatar(radius: 30, backgroundColor: AppColors.primary, backgroundImage: logo != null ? NetworkImage(logo) : null, child: logo != null ? null : Text(nombre[0].toUpperCase(), style: const TextStyle(fontSize: 22, color: AppColors.textWhite, fontWeight: FontWeight.bold))),
        const SizedBox(height: 8),
        Text(nombre, textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13, color: AppColors.textWhite, fontWeight: FontWeight.w600)),
      ]),
    );
  }

  Widget _marcador(Map<String, dynamic> e) {
    final tiene = e['resultado_local'] != null && e['resultado_visitante'] != null;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
      decoration: BoxDecoration(color: AppColors.bgCard, borderRadius: BorderRadius.circular(16)),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _equipo(e['equipo_local'] as Map<String, dynamic>?),
        Padding(padding: const EdgeInsets.only(top: 14, left: 8, right: 8), child: Text(tiene ? '${e['resultado_local']} : ${e['resultado_visitante']}' : 'VS', style: TextStyle(fontSize: tiene ? 32 : 20, color: tiene ? AppColors.textWhite : AppColors.textGray, fontWeight: FontWeight.bold))),
        _equipo(e['equipo_visitante'] as Map<String, dynamic>?),
      ]),
    );
  }

  Widget _fila(IconData icono, String titulo, String valor) => Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: AppColors.bgCard, borderRadius: BorderRadius.circular(12)),
        child: Row(children: [
          Icon(icono, color: AppColors.secondary, size: 22),
          const SizedBox(width: 12),
          Text(titulo, style: const TextStyle(fontSize: 13, color: AppColors.textGray)),
          const SizedBox(width: 12),
          Expanded(child: Text(valor, textAlign: TextAlign.end, style: const TextStyle(fontSize: 14, color: AppColors.textWhite, fontWeight: FontWeight.w600))),
        ]),
      );

  Widget _accion(IconData icono, String titulo, VoidCallback onTap, {Color color = AppColors.textWhite}) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Material(
          color: AppColors.bgCard,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: onTap,

            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(children: [
                Icon(icono, color: color),
                const SizedBox(width: 12),
                Expanded(child: Text(titulo, style: TextStyle(color: color, fontWeight: FontWeight.w600))),
                const Icon(Icons.chevron_right, color: AppColors.textGray),
              ]),
            ),
          ),
        ),
      );
}