import 'package:flutter/material.dart';
import '../../components/partido_tile.dart';
import '../../components/ui_kit.dart';
import '../../core/app_colors.dart';
import '../../core/roles.dart';
import '../../models/models.dart';
import '../../services/auth_service.dart';
import '../../services/panel_service.dart';
import '../../services/team_service.dart';
import '../event_detail_page.dart';

/// Inicio del JUGADOR: su próximo partido, su equipo, invitaciones y un resumen de sus estadísticas de juego
class JugadorInicioPage extends StatelessWidget {
  final ValueChanged<int> onIrATab;
  const JugadorInicioPage({super.key, required this.onIrATab});

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: AppColors.bgDark,
        body: SafeArea(
          child: CargadorLista<PanelJugador>(
            cargar: PanelService.jugador,
            construir: (context, p, recargar) {
              final nombre = AuthService.usuario?['nombre'] ?? '';
              final equipo = p.equipoPrincipal;
              final e = p.estadisticas;
              return [
                CabeceraRol(
                  saludo: 'Hola, $nombre',
                  subtitulo: equipo == null ? 'Aún no tienes equipo' : 'Juegas en ${equipo.nombre}${equipo.dorsal != null ? ' · #${equipo.dorsal}' : ''}',
                  icono: RolApp.jugador.icono,
                  color: RolApp.jugador.color,
                ),
                if (p.invitaciones.isNotEmpty) ...[
                  const SeccionTitulo('Invitaciones a equipos'),
                  for (final i in p.invitaciones) _Invitacion(invitacion: i, onResuelta: recargar),
                ],
                const SeccionTitulo('Mi próximo partido'),
                if (p.proximos.isEmpty)
                  TarjetaBase(child: EstadoVacio(icono: Icons.event_busy_outlined, mensaje: equipo == null ? 'Cuando un entrenador te invite a su equipo, verás aquí tus partidos' : 'Tu equipo no tiene partidos programados'))
                else
                  for (final partido in p.proximos.take(3))
                    PartidoTile(partido: partido, mostrarFecha: true, destacarEquipoId: equipo?.id, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => EventDetailPage(eventoId: partido.id)))),
                SeccionTitulo('Mis estadísticas', accion: 'Ver perfil', onAccion: () => onIrATab(4)),
                KpiGrid([
                  KpiTile(icono: Icons.sports_soccer, valor: '${e.goles}', etiqueta: 'Goles', color: AppColors.orange),
                  KpiTile(icono: Icons.handshake_outlined, valor: '${e.asistencias}', etiqueta: 'Asistencias', color: AppColors.secondary),
                  KpiTile(icono: Icons.event_available, valor: '${e.partidos}', etiqueta: 'Partidos', color: AppColors.primaryLight),
                  KpiTile(icono: Icons.style, valor: '${e.tarjetas}', etiqueta: 'Tarjetas', color: AppColors.warning),
                ]),
                if (p.equipos.length > 1) ...[
                  const SeccionTitulo('Mis equipos'),
                  for (final eq in p.equipos)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: TarjetaBase(
                        onTap: () => onIrATab(2),
                        padding: const EdgeInsets.all(12),
                        child: Row(children: [
                          EquipoAvatar(nombre: eq.nombre, logoUrl: eq.logoUrl),
                          const SizedBox(width: 12),
                          Expanded(child: Text(eq.nombre, style: const TextStyle(color: AppColors.textWhite, fontWeight: FontWeight.w600))),
                          Text(eq.posicion ?? '', style: const TextStyle(fontSize: 12, color: AppColors.textGray)),
                        ]),
                      ),
                    ),
                ],
              ];
            },
          ),
        ),
      );
}

class _Invitacion extends StatefulWidget {
  final Invitacion invitacion;
  final Future<void> Function() onResuelta;
  const _Invitacion({required this.invitacion, required this.onResuelta});

  @override
  State<_Invitacion> createState() => _InvitacionState();
}

class _InvitacionState extends State<_Invitacion> {
  bool _enviando = false;

  Future<void> _responder(bool aceptar) async {
    setState(() => _enviando = true);
    final r = await TeamService.responderInvitacion(widget.invitacion.id, aceptar);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(r['mensaje'].toString())));
    await widget.onResuelta();
    if (mounted) setState(() => _enviando = false);
  }

  @override
  Widget build(BuildContext context) {
    final i = widget.invitacion;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: TarjetaBase(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            EquipoAvatar(nombre: i.equipo?.nombre ?? '?', logoUrl: i.equipo?.logoUrl),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(i.equipo?.nombre ?? 'Equipo', style: const TextStyle(color: AppColors.textWhite, fontWeight: FontWeight.bold)),
                Text(i.posicionPropuesta == null ? 'Te invita a unirte' : 'Te invita como ${i.posicionPropuesta}', style: const TextStyle(fontSize: 12, color: AppColors.textGray)),
              ]),
            ),
          ]),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: OutlinedButton(onPressed: _enviando ? null : () => _responder(false), child: const Text('Rechazar'))),
            const SizedBox(width: 10),
            Expanded(child: FilledButton(onPressed: _enviando ? null : () => _responder(true), child: const Text('Aceptar'))),
          ]),
        ]),
      ),
    );
  }
}
