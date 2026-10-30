import 'package:flutter/material.dart';
import '../../components/admin_widgets.dart';
import '../../components/tournament_chip.dart';
import '../../components/ui_kit.dart';
import '../../core/app_colors.dart';
import '../../core/roles.dart';
import '../../models/models.dart';
import '../../services/team_service.dart';
import '../../services/tournament_service.dart';

/// Equipos del torneo. El organizador dueño acepta o rechaza las inscripciones;
/// el entrenador puede inscribir uno de sus equipos; el resto solo consulta.
class TorneoEquiposTab extends StatefulWidget {
  final Torneo torneo;
  final bool esGestor;
  final Set<String> mios;
  final Future<void> Function() onCambio;
  const TorneoEquiposTab({super.key, required this.torneo, required this.esGestor, required this.mios, required this.onCambio});

  @override
  State<TorneoEquiposTab> createState() => _TorneoEquiposTabState();
}

class _TorneoEquiposTabState extends State<TorneoEquiposTab> {
  void _aviso(String t) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t)));

  Future<void> _resolver(Inscripcion i, String estado, Future<void> Function() recargar) async {
    final ok = await confirmar(context, titulo: estado == 'Aceptado' ? 'Aceptar equipo' : 'Rechazar equipo', mensaje: '${i.equipo?.nombre ?? 'El equipo'} quedará como $estado en el torneo.', accion: estado == 'Aceptado' ? 'Aceptar' : 'Rechazar', peligro: estado == 'Rechazado');
    if (!ok) return;
    final r = await TournamentService.resolverInscripcion(i.id, estado);
    if (!mounted) return;
    if (r['exito'] != true) return _aviso(r['mensaje'].toString());
    await recargar();
    await widget.onCambio();
  }

  Future<void> _inscribir(List<Inscripcion> actuales, Future<void> Function() recargar) async {
    final mios = await TeamService.mios();
    if (!mounted) return;
    if (!mios.ok) return _aviso(mios.error!);
    final yaInscritos = actuales.map((i) => '${i.equipo?.id}').toSet();
    final libres = mios.dato!.where((e) => !yaInscritos.contains('${e.id}')).toList();
    if (libres.isEmpty) return _aviso(mios.dato!.isEmpty ? 'Primero crea un equipo en la pestaña Equipos' : 'Todos tus equipos ya están inscritos en este torneo');
    final elegido = await showModalBottomSheet<Equipo>(
      context: context,
      backgroundColor: AppColors.bgCard,
      builder: (c) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Padding(padding: EdgeInsets.all(16), child: Text('¿Qué equipo inscribes?', style: TextStyle(fontSize: 16, color: AppColors.textWhite, fontWeight: FontWeight.bold))),
          for (final e in libres) ListTile(leading: EquipoAvatar(nombre: e.nombre, logoUrl: e.logoUrl, tamano: 36), title: Text(e.nombre, style: const TextStyle(color: AppColors.textWhite)), onTap: () => Navigator.pop(c, e)),
          const SizedBox(height: 8),
        ]),
      ),
    );
    if (elegido == null) return;
    final r = await TeamService.inscribirEnTorneo(elegido.id, widget.torneo.id);
    if (!mounted) return;
    _aviso(r['exito'] == true ? 'Solicitud enviada: el organizador debe aceptarla' : r['mensaje'].toString());
    await recargar();
    await widget.onCambio();
  }

  @override
  Widget build(BuildContext context) {
    final rol = RolApp.actual;
    return CargadorLista<List<Inscripcion>>(
      cargar: () => TournamentService.inscripciones(widget.torneo.id),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
      construir: (context, lista, recargar) {
        final aceptados = lista.where((i) => i.estado == 'Aceptado').toList();
        final pendientes = lista.where((i) => i.estado == 'Pendiente' && (widget.esGestor || widget.mios.contains('${i.equipo?.id}'))).toList();
        final rechazados = lista.where((i) => i.estado == 'Rechazado' && (widget.esGestor || widget.mios.contains('${i.equipo?.id}'))).toList();
        return [
          if (rol == RolApp.entrenador && !widget.torneo.cerrado)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: FilledButton.icon(onPressed: () => _inscribir(lista, recargar), icon: const Icon(Icons.how_to_reg), label: const Text('Inscribir mi equipo')),
            ),
          Text('${aceptados.length} de ${widget.torneo.maxEquipos == 0 ? '-' : widget.torneo.maxEquipos} equipos confirmados', style: const TextStyle(color: AppColors.textGray, fontSize: 12.5)),
          if (pendientes.isNotEmpty) ...[
            SeccionTitulo(widget.esGestor ? 'Solicitudes por resolver' : 'Mis solicitudes'),
            for (final i in pendientes) _fila(i, recargar),
          ],
          const SeccionTitulo('Equipos participantes'),
          if (aceptados.isEmpty) const EstadoVacio(icono: Icons.groups_outlined, mensaje: 'Aún no hay equipos confirmados'),
          for (final i in aceptados) _fila(i, recargar),
          if (rechazados.isNotEmpty) ...[
            const SeccionTitulo('Rechazados'),
            for (final i in rechazados) _fila(i, recargar),
          ],
        ];
      },
    );
  }

  Widget _fila(Inscripcion i, Future<void> Function() recargar) {
    final e = i.equipo;
    final mio = widget.mios.contains('${e?.id}');
    final pendiente = i.estado == 'Pendiente';
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: TarjetaBase(
        padding: const EdgeInsets.all(12),
        child: Row(children: [
          EquipoAvatar(nombre: e?.nombre ?? '?', logoUrl: e?.logoUrl, tamano: 38),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(e?.nombre ?? 'Equipo', style: const TextStyle(color: AppColors.textWhite, fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              Wrap(spacing: 6, children: [
                TournamentChip(i.estado, color: switch (i.estado) { 'Aceptado' => AppColors.success, 'Rechazado' => AppColors.error, _ => AppColors.warning }),
                if (mio) const TournamentChip('Mi equipo', color: AppColors.secondary, icono: Icons.star),
              ]),
            ]),
          ),
          if (widget.esGestor && pendiente) ...[
            IconButton(tooltip: 'Rechazar', onPressed: () => _resolver(i, 'Rechazado', recargar), icon: const Icon(Icons.close, color: AppColors.error)),
            IconButton(tooltip: 'Aceptar', onPressed: () => _resolver(i, 'Aceptado', recargar), icon: const Icon(Icons.check_circle, color: AppColors.success)),
          ],
        ]),
      ),
    );
  }
}
