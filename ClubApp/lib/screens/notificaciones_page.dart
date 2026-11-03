import 'package:flutter/material.dart';
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
/// inscripciones a torneos e invitaciones a equipos. Toca una para abrir lo que anuncia; desliza para borrarla.
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

  Future<void> _abrir(Notificacion n) async {
    if (!n.leida) {
      setState(() => _lista = [for (final x in _lista!) '${x.id}' == '${n.id}' ? x.copiarLeida() : x]);
      NotificationService.marcarLeida(n.id);
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

  Future<void> _borrar(Notificacion n) async {
    setState(() => _lista = _lista!.where((x) => '${x.id}' != '${n.id}').toList());
    final ok = await NotificationService.eliminar(n.id);
    if (!mounted) return;
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No se pudo eliminar la notificación')));
      _cargar();
    } else {
      NotificationService.consultar();
    }
  }

  Future<void> _marcarTodas() async {
    final ok = await NotificationService.marcarTodas();
    if (!mounted) return;
    if (ok) setState(() => _lista = [for (final x in _lista ?? <Notificacion>[]) x.copiarLeida()]);
  }

  String _etiquetaDia(String iso) {
    final hoy = DateTime.now();
    final ayer = hoy.subtract(const Duration(days: 1));
    if (iso == isoFecha(hoy)) return 'Hoy';
    if (iso == isoFecha(ayer)) return 'Ayer';
    return fechaLarga(DateTime.parse(iso));
  }

  @override
  Widget build(BuildContext context) {
    final sinLeer = (_lista ?? []).where((n) => !n.leida).length;
    return RoleGuard(
      roles: RolApp.values.toSet(), // cualquier sesión iniciada (los invitados no tienen notificaciones)
      child: Scaffold(
        backgroundColor: AppColors.bgDark,
        appBar: AppBar(
          backgroundColor: AppColors.bgDark,
          elevation: 0,
          title: const Text('Notificaciones'),
          actions: [
            if (sinLeer > 0) TextButton.icon(onPressed: _marcarTodas, icon: const Icon(Icons.done_all, size: 18), label: const Text('Marcar leídas')),
          ],
        ),
        body: _cuerpo,
      ),
    );
  }

  Widget get _cuerpo {
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
    final todas = _lista ?? [];
    final visibles = _filtro == 'nuevas' ? todas.where((n) => !n.leida).toList() : todas;

    final hijos = <Widget>[
      FiltroChips<String>(opciones: const {'Todas': null, 'Sin leer': 'nuevas'}, valor: _filtro, onChanged: (v) => setState(() => _filtro = v)),
      const SizedBox(height: 8),
    ];
    if (visibles.isEmpty) {
      hijos.add(EstadoVacio(icono: Icons.notifications_none_rounded, mensaje: _filtro == 'nuevas' ? 'No tienes notificaciones sin leer' : 'Todavía no tienes notificaciones.\nAquí verás tus partidos, resultados e invitaciones.'));
    }
    String? dia;
    for (final n in visibles) {
      if (n.dia != dia) {
        dia = n.dia;
        hijos.add(Padding(padding: const EdgeInsets.only(top: 14, bottom: 8), child: Text(_etiquetaDia(n.dia), style: const TextStyle(fontSize: 13, color: AppColors.secondary, fontWeight: FontWeight.bold))));
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
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Dismissible(
        key: ValueKey('notif-${n.id}'),
        direction: DismissDirection.endToStart,
        onDismissed: (_) => onBorrar(),
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20),
          decoration: BoxDecoration(color: AppColors.error.withValues(alpha: 0.85), borderRadius: BorderRadius.circular(16)),
          child: const Icon(Icons.delete_outline, color: Colors.white),
        ),
        child: TarjetaBase(
          onTap: onTap,
          padding: const EdgeInsets.all(14),
          color: n.leida ? AppColors.bgCard : AppColors.bgCard.withValues(alpha: 1),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: n.color.withValues(alpha: 0.16), shape: BoxShape.circle),
              child: Icon(n.icono, color: n.color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(n.titulo, style: TextStyle(fontSize: 14, height: 1.3, color: n.leida ? AppColors.textGray : AppColors.textWhite, fontWeight: n.leida ? FontWeight.w400 : FontWeight.w600)),
                const SizedBox(height: 4),
                Text(n.hace, style: const TextStyle(fontSize: 11.5, color: AppColors.textGrayDark)),
              ]),
            ),
            if (!n.leida) Container(margin: const EdgeInsets.only(top: 6, left: 8), width: 9, height: 9, decoration: const BoxDecoration(color: AppColors.secondary, shape: BoxShape.circle)),
          ]),
        ),
      ),
    );
  }
}