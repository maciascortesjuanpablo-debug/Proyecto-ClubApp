import 'package:flutter/material.dart';
import '../../components/partido_tile.dart';
import '../../components/tournament_chip.dart';
import '../../components/ui_kit.dart';
import '../../core/app_colors.dart';
import '../../core/roles.dart';
import '../../models/models.dart';
import '../../services/auth_service.dart';
import '../../services/panel_service.dart';
import '../event_detail_page.dart';
import '../scout_page.dart';
import '../torneo/torneo_page.dart';

/// Inicio del ENTRENADOR: sus equipos, inscripciones a torneos y próximos partidos
class EntrenadorInicioPage extends StatelessWidget {
  final ValueChanged<int> onIrATab;
  const EntrenadorInicioPage({super.key, required this.onIrATab});

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: AppColors.bgDark,
        body: SafeArea(
          child: CargadorLista<PanelEntrenador>(
            cargar: PanelService.entrenador,
            construir: (context, p, recargar) => [
              CabeceraRol(
                saludo: 'Hola, ${AuthService.usuario?['nombre'] ?? ''}',
                subtitulo: p.totalEquipos == 0 ? 'Crea tu primer equipo para empezar' : 'Diriges ${p.totalEquipos} equipo${p.totalEquipos == 1 ? '' : 's'} y ${p.totalJugadores} jugadores',
                icono: RolApp.entrenador.icono,
                color: RolApp.entrenador.color,
              ),
              const SizedBox(height: 14),
              KpiGrid([
                KpiTile(icono: Icons.groups, valor: '${p.totalEquipos}', etiqueta: 'Equipos', color: AppColors.orange),
                KpiTile(icono: Icons.person, valor: '${p.totalJugadores}', etiqueta: 'Jugadores', color: AppColors.secondary, detalle: p.invitacionesPendientes > 0 ? '${p.invitacionesPendientes} invitaciones sin responder' : null),
                KpiTile(icono: Icons.emoji_events, valor: '${p.torneosActivos}', etiqueta: 'Torneos activos', color: AppColors.success),
                KpiTile(icono: Icons.hourglass_top, valor: '${p.inscripcionesPendientes}', etiqueta: 'Esperando respuesta', color: AppColors.warning),
              ]),
              SeccionTitulo('Mis equipos', accion: 'Gestionar', onAccion: () => onIrATab(2)),
              if (p.equipos.isEmpty)
                TarjetaBase(child: EstadoVacio(icono: Icons.groups_outlined, mensaje: 'Aún no tienes equipos', accion: FilledButton(onPressed: () => onIrATab(2), child: const Text('Crear equipo'))))
              else
                for (final e in p.equipos) _equipo(context, e),
              const SeccionTitulo('Próximos partidos'),
              if (p.proximos.isEmpty)
                const TarjetaBase(child: EstadoVacio(icono: Icons.event_busy_outlined, mensaje: 'Tus equipos no tienen partidos programados'))
              else
                for (final partido in p.proximos) PartidoTile(partido: partido, mostrarFecha: true, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => EventDetailPage(eventoId: partido.id)))),
              const SeccionTitulo('Herramientas'),
              TarjetaBase(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ScoutPage())),
                child: const Row(children: [
                  Icon(Icons.smart_toy_outlined, color: AppColors.secondary, size: 28),
                  SizedBox(width: 14),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Scout AI', style: TextStyle(color: AppColors.textWhite, fontWeight: FontWeight.bold)),
                    Text('Recomendaciones de jugadores y reportes de tu equipo', style: TextStyle(fontSize: 12, color: AppColors.textGray)),
                  ])),
                  Icon(Icons.chevron_right, color: AppColors.textGray),
                ]),
              ),
            ],
          ),
        ),
      );

  Widget _equipo(BuildContext context, Equipo e) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: TarjetaBase(
          onTap: () => onIrATab(2),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              EquipoAvatar(nombre: e.nombre, logoUrl: e.logoUrl),
              const SizedBox(width: 12),
              Expanded(child: Text(e.nombre, style: const TextStyle(fontSize: 15, color: AppColors.textWhite, fontWeight: FontWeight.bold))),
              Text('${e.jugadores} jugadores', style: const TextStyle(fontSize: 12, color: AppColors.textGray)),
            ]),
            if (e.inscripciones.isNotEmpty) ...[
              const SizedBox(height: 10),
              Wrap(spacing: 6, runSpacing: 6, children: [
                for (final i in e.inscripciones)
                  GestureDetector(
                    onTap: i.torneo == null ? null : () => Navigator.push(context, MaterialPageRoute(builder: (_) => TorneoPage(torneoId: i.torneo!.id, nombre: i.torneo!.nombre))),
                    child: TournamentChip('${i.torneo?.nombre ?? 'Torneo'} · ${i.estado}', color: switch (i.estado) { 'Aceptado' => AppColors.success, 'Rechazado' => AppColors.error, _ => AppColors.warning }, icono: Icons.emoji_events),
                  ),
              ]),
            ],
          ]),
        ),
      );
}
