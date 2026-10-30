import 'package:flutter/material.dart';
import '../../components/partido_tile.dart';
import '../../components/ui_kit.dart';
import '../../core/app_colors.dart';
import '../../core/roles.dart';
import '../../models/models.dart';
import '../../services/auth_service.dart';
import '../../services/panel_service.dart';
import '../event_detail_page.dart';

/// Inicio del ÁRBITRO: sus partidos de hoy, las próximas designaciones y su actividad como juez.
/// No muestra nada de estadísticas de jugador: un árbitro no juega.
class ArbitroInicioPage extends StatelessWidget {
  final ValueChanged<int> onIrATab;
  const ArbitroInicioPage({super.key, required this.onIrATab});

  void _abrir(BuildContext context, Partido p) => Navigator.push(context, MaterialPageRoute(builder: (_) => EventDetailPage(eventoId: p.id)));

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: AppColors.bgDark,
        body: SafeArea(
          child: CargadorLista<PanelArbitro>(
            cargar: PanelService.arbitro,
            construir: (context, p, recargar) => [
              CabeceraRol(
                saludo: 'Hola, ${AuthService.usuario?['nombre'] ?? ''}',
                subtitulo: p.hoy.isEmpty ? (p.porDirigir == 0 ? 'No tienes partidos asignados por ahora' : 'Hoy no tienes partidos') : 'Hoy dirigues ${p.hoy.length} partido${p.hoy.length == 1 ? '' : 's'}',
                icono: RolApp.arbitro.icono,
                color: RolApp.arbitro.color,
              ),
              const SeccionTitulo('Hoy'),
              if (p.hoy.isEmpty) const TarjetaBase(child: EstadoVacio(icono: Icons.wb_sunny_outlined, mensaje: 'Sin partidos para hoy'))
              else for (final partido in p.hoy) PartidoTile(partido: partido, etiqueta: partido.rolArbitraje, onTap: () => _abrir(context, partido)),
              SeccionTitulo('Próximas designaciones', accion: 'Ver todas', onAccion: () => onIrATab(1)),
              if (p.proximos.isEmpty) const TarjetaBase(child: EstadoVacio(icono: Icons.event_busy_outlined, mensaje: 'Aún no te han asignado más partidos'))
              else for (final partido in p.proximos.take(3)) PartidoTile(partido: partido, mostrarFecha: true, etiqueta: partido.rolArbitraje, onTap: () => _abrir(context, partido)),
              const SeccionTitulo('Mi actividad'),
              KpiGrid([
                KpiTile(icono: Icons.sports_score, valor: '${p.dirigidos}', etiqueta: 'Partidos dirigidos', color: AppColors.warning),
                KpiTile(icono: Icons.upcoming, valor: '${p.porDirigir}', etiqueta: 'Por dirigir', color: AppColors.primaryLight),
                KpiTile(icono: Icons.style, valor: '${p.tarjetas}', etiqueta: 'Tarjetas mostradas', color: AppColors.error, detalle: '${p.amarillas} amarillas · ${p.rojas} rojas'),
                KpiTile(icono: Icons.emoji_events, valor: '${p.torneos.length}', etiqueta: 'Torneos donde participo', color: AppColors.secondary),
              ]),
            ],
          ),
        ),
      );
}
