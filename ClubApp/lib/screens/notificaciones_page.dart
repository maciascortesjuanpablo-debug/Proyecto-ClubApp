import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../components/admin_widgets.dart';
import '../components/role_guard.dart';
import '../components/ui_kit.dart';
import '../core/app_colors.dart';
import '../core/calendar_utils.dart';
import '../core/roles.dart';
import '../models/models.dart';
import '../services/notification_service.dart';
import 'event_detail_page.dart';
import 'torneo/torneo_page.dart';

/// Lista de notificaciones: partidos nuevos o reprogramados, resultados, designaciones de árbitro,
/// inscripciones a torneos e invitaciones a equipos. Toca una para abrir lo que anuncia; desliza para borrarla (con deshacer).
class NotificacionesPage extends StatefulWidget {
  const NotificacionesPage({super.key});

  @override
  State<NotificacionesPage> createState() => _NotificacionesPageState();
}

class _NotificacionesPageState extends State<NotificacionesPage> {
  List<Notificacion>? _lista;
  String? _error;
  bool _cargando = true;
  String? _filtro; // null = todas, 'nuevas' = sin leer

  @override
  void initState() {
    super.initState();
    NotificationService.paginaAbierta(true);
    _cargar();
  }

  @override
  void dispose() {
    NotificationService.paginaAbierta(false);
    super.dispose();
  }

  Future<void> _cargar() async {
    final r = await NotificationService.listar();
    if (!mounted) return;
    setState(() {
      _cargando = false;
      _error = r.error;
      _lista = r.dato;
    });
    NotificationService.consultar(); // deja el contador de la campana al día
  }

  Object _id(String s) => int.tryParse(s) ?? s;
  bool _mismo(Notificacion a, Notificacion b) => '${a.id}' == '${b.id}';

  Future<void> _abrir(Notificacion n) async {
    HapticFeedback.selectionClick();
    if (!n.leida) {
      setState(() => _lista = [for (final x in _lista!) _mismo(x, n) ? x.copiarLeida() : x]);
      NotificationService.marcarLeida(n.id).then((_) => NotificationService.consultar());
    }
    final ref = n.referenciaId;
    if (ref == null) return;
    switch (n.tipo) {
      case 'partido' || 'resultado' || 'designacion':
        await Navigator.push(context, MaterialPageRoute(builder: (_) => EventDetailPage(eventoId: _id(ref))));
      case 'torneo':
        await Navigator.push(context, MaterialPageRoute(builder: (_) => TorneoPage(torneoId: _id(ref), nombre: 'Torneo')));
    }
  }

  /// Quita la tarjeta al instante y solo borra en el servidor si no se pulsa "Deshacer".
  Future<void> _borrar(Notificacion n) async {
    final pos = _lista!.indexWhere((x) => _mismo(x, n));
    var deshecho = false;
    setState(() => _lista = _lista!.where((x) => !_mismo(x, n)).toList());
    final messenger = ScaffoldMessenger.of(context)..hideCurrentSnackBar();
    await messenger
        .showSnackBar(SnackBar(
          content: const Text('Notificación eliminada'),
          duration: const Duration(seconds: 4),
          action: SnackBarAction(
            label: 'Deshacer',
            onPressed: () {
              deshecho = true;
              if (mounted) setState(() => _lista = [..._lista!]..insert(min(max(pos, 0), _lista!.length), n));
            },
          ),
        ))
        .closed;
    if (deshecho) return;
    final ok = await NotificationService.eliminar(n.id);
    if (!mounted) return;
    if (!ok) {
      messenger.showSnackBar(const SnackBar(content: Text('No se pudo eliminar la notificación')));
      _cargar();
    } else {
      NotificationService.consultar();
    }
  }

  Future<void> _marcarTodas() async {
    final ok = await NotificationService.marcarTodas();
    if (!mounted) return;
    if (ok) {
      HapticFeedback.lightImpact();
      setState(() => _lista = [for (final x in _lista ?? <Notificacion>[]) x.copiarLeida()]);
      NotificationService.consultar();
    }
  }

  Future<void> _borrarLeidas() async {
    final leidas = (_lista ?? []).where((n) => n.leida).toList();
    if (leidas.isEmpty) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Borrar leídas'),
        content: Text('Se eliminarán ${leidas.length} notificaciones leídas.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancelar')),
          TextButton(onPressed: () => Navigator.pop(c, true), child: const Text('Borrar')),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    setState(() => _lista = _lista!.where((n) => !n.leida).toList());
    await Future.wait(leidas.map((n) => NotificationService.eliminar(n.id)));
    NotificationService.consultar();
  }

  String _etiquetaDia(String iso) {
    final hoy = DateTime.now();
    if (iso == isoFecha(hoy)) return 'Hoy';
    if (iso == isoFecha(hoy.subtract(const Duration(days: 1)))) return 'Ayer';
    return fechaLarga(DateTime.parse(iso));
  }

  @override
  Widget build(BuildContext context) {
    final lista = _lista ?? [];
    final sinLeer = lista.where((n) => !n.leida).length;
    return RoleGuard(
      roles: RolApp.values.toSet(), // cualquier sesión iniciada (los invitados no tienen notificaciones)
      child: Scaffold(
        backgroundColor: AppColors.bgDark,
        appBar: AppBar(
          backgroundColor: AppColors.bgDark,
          elevation: 0,
          title: const Text('Notificaciones'),
          actions: [
            if (sinLeer > 0) IconButton(tooltip: 'Marcar todas como leídas', onPressed: _marcarTodas, icon: const Icon(Icons.done_all)),
            if (lista.any((n) => n.leida))
              PopupMenuButton<String>(
                onSelected: (_) => _borrarLeidas(),
                itemBuilder: (_) => const [PopupMenuItem(value: 'borrar', child: Text('Borrar leídas'))],
              ),
          ],
        ),
        body: _cuerpo(lista, sinLeer),
      ),
    );
  }

  Widget _cuerpo(List<Notificacion> todas, int sinLeer) {
    if (_cargando) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Padding(padding: const EdgeInsets.symmetric(horizontal: 24), child: Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textGray))),
          const SizedBox(height: 12),
          OutlinedButton(onPressed: () { setState(() => _cargando = true); _cargar(); }, child: const Text('Reintentar')),
        ]),
      );
    }
    final soloNuevas = _filtro == 'nuevas';
    final visibles = soloNuevas ? todas.where((n) => !n.leida).toList() : todas;

    final hijos = <Widget>[
      FiltroChips<String>(opciones: {'Todas': null, 'Sin leer ($sinLeer)': 'nuevas'}, valor: _filtro, onChanged: (v) => setState(() => _filtro = v)),
      const SizedBox(height: 8),
      if (visibles.isEmpty)
        EstadoVacio(
          icono: soloNuevas ? Icons.done_all_rounded : Icons.notifications_none_rounded,
          mensaje: soloNuevas ? 'Estás al día, no tienes notificaciones sin leer' : 'Todavía no tienes notificaciones.\nAquí verás tus partidos, resultados e invitaciones.',
        ),
    ];
    String? dia;
    for (final n in visibles) {
      if (n.dia != dia) {
        dia = n.dia;
        final cuenta = visibles.where((x) => x.dia == dia).length;
        hijos.add(Padding(
          padding: const EdgeInsets.only(top: 14, bottom: 8),
          child: Row(children: [
            Text(_etiquetaDia(n.dia), style: const TextStyle(fontSize: 13, color: AppColors.secondary, fontWeight: FontWeight.bold)),
            const SizedBox(width: 6),
            Text('· $cuenta', style: const TextStyle(fontSize: 12, color: AppColors.textGrayDark)),
          ]),
        ));
      }
      hijos.add(_Tarjeta(notificacion: n, onTap: () => _abrir(n), onBorrar: () => _borrar(n)));
    }
    return RefreshIndicator(
      onRefresh: _cargar,
      child: ListView(physics: const AlwaysScrollableScrollPhysics(), padding: const EdgeInsets.fromLTRB(16, 12, 16, 40), children: hijos),
    );
  }
}

class _Tarjeta extends StatelessWidget {
  final Notificacion notificacion;
  final VoidCallback onTap;
  final VoidCallback onBorrar;
  const _Tarjeta({required this.notificacion, required this.onTap, required this.onBorrar});

  @override
  Widget build(BuildContext context) {
    final n = notificacion;
    final nueva = !n.leida;
    final radio = BorderRadius.circular(16);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Dismissible(
        key: ValueKey('notif-${n.id}'),
        direction: DismissDirection.endToStart,
        onDismissed: (_) {
          HapticFeedback.mediumImpact();
          onBorrar();
        },
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20),
          decoration: BoxDecoration(color: AppColors.error.withValues(alpha: 0.85), borderRadius: radio),
          child: const Icon(Icons.delete_outline, color: Colors.white),
        ),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          decoration: BoxDecoration(
            color: nueva ? Color.alphaBlend(AppColors.secondary.withValues(alpha: 0.10), AppColors.bgCard) : AppColors.bgCard.withValues(alpha: 0.45),
            borderRadius: radio,
            border: Border.all(color: nueva ? AppColors.secondary.withValues(alpha: 0.5) : Colors.white.withValues(alpha: 0.05)),
          ),
          child: Material(
            type: MaterialType.transparency,
            child: InkWell(
              borderRadius: radio,
              onTap: onTap,
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 300),
                  opacity: nueva ? 1 : 0.6,
                  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(color: n.color.withValues(alpha: 0.16), shape: BoxShape.circle),
                      child: Icon(n.icono, color: n.color, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(n.titulo, style: TextStyle(fontSize: 14, height: 1.3, color: nueva ? AppColors.textWhite : AppColors.textGray, fontWeight: nueva ? FontWeight.w700 : FontWeight.w400)),
                        const SizedBox(height: 4),
                        Text(n.hace, style: TextStyle(fontSize: 11.5, color: nueva ? AppColors.secondary : AppColors.textGrayDark)),
                      ]),
                    ),
                    const SizedBox(width: 8),
                    nueva
                        ? Container(margin: const EdgeInsets.only(top: 6), width: 10, height: 10, decoration: const BoxDecoration(color: AppColors.secondary, shape: BoxShape.circle))
                        : const Padding(padding: EdgeInsets.only(top: 2), child: Icon(Icons.done_all, size: 16, color: AppColors.textGrayDark)),
                  ]),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}