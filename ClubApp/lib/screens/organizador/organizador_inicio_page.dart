import 'package:flutter/material.dart';
import '../../components/charts.dart';
import '../../components/partido_tile.dart';
import '../../components/tournament_chip.dart';
import '../../components/ui_kit.dart';
import '../../core/app_colors.dart';
import '../../core/roles.dart';
import '../../models/models.dart';
import '../../services/auth_service.dart';
import '../../services/panel_service.dart';
import '../create_tournament_page.dart';
import '../event_detail_page.dart';
import '../scout_page.dart';
import '../torneo/torneo_page.dart';

/// Inicio del ORGANIZADOR: sus torneos, lo que está pendiente de resolver y los próximos partidos
class OrganizadorInicioPage extends StatefulWidget {
  final ValueChanged<int> onIrATab;
  const OrganizadorInicioPage({super.key, required this.onIrATab});

  @override
  State<OrganizadorInicioPage> createState() => _OrganizadorInicioPageState();
}

class _OrganizadorInicioPageState extends State<OrganizadorInicioPage> {
  int _version = 0;

  Future<void> _crear() async {
    final creado = await Navigator.push<bool>(context, MaterialPageRoute(builder: (_) => const CreateTournamentPage()));
    if (creado == true && mounted) setState(() => _version++);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: AppColors.bgDark,
        body: SafeArea(
          child: CargadorLista<PanelOrganizador>(
            key: ValueKey(_version),
            cargar: PanelService.organizador,
            construir: (context, p, recargar) => [
              CabeceraRol(
                saludo: 'Hola, ${AuthService.usuario?['nombre'] ?? ''}',
                subtitulo: p.totalTorneos == 0 ? 'Crea tu primer torneo' : 'Organizas ${p.totalTorneos} torneo${p.totalTorneos == 1 ? '' : 's'}',
                icono: RolApp.organizador.icono,
                color: RolApp.organizador.color,
              ),
              const SizedBox(height: 14),
              KpiGrid([
                KpiTile(icono: Icons.emoji_events, valor: '${p.totalTorneos}', etiqueta: 'Torneos', color: AppColors.primaryLight),
                KpiTile(icono: Icons.groups, valor: '${p.totalEquipos}', etiqueta: 'Equipos confirmados', color: AppColors.orange),
                KpiTile(icono: Icons.today, valor: '${p.partidosHoy}', etiqueta: 'Partidos hoy', color: AppColors.success),
                KpiTile(icono: Icons.date_range, valor: '${p.partidosSemana}', etiqueta: 'En los próximos 7 días', color: AppColors.secondary),
              ]),
              if (p.pendientes.isNotEmpty || p.sinArbitro > 0) ...[
                const SeccionTitulo('Requiere tu atención'),
                if (p.pendientes.isNotEmpty) _alerta(Icons.how_to_reg, '${p.pendientes.length} solicitud${p.pendientes.length == 1 ? '' : 'es'} de inscripción', 'Equipos esperando tu respuesta', AppColors.warning, () => widget.onIrATab(2)),
                if (p.sinArbitro > 0) _alerta(Icons.sports_score, '${p.sinArbitro} partido${p.sinArbitro == 1 ? '' : 's'} sin árbitro', 'Asigna un árbitro desde el detalle del partido', AppColors.error, () => widget.onIrATab(3)),
              ],
              SeccionTitulo('Mis torneos', accion: 'Ver todos', onAccion: () => widget.onIrATab(1)),
              if (p.torneos.isEmpty)
                TarjetaBase(child: EstadoVacio(icono: Icons.emoji_events_outlined, mensaje: 'Aún no has creado torneos', accion: FilledButton(onPressed: _crear, child: const Text('Crear torneo'))))
              else
                for (final t in p.torneos.take(4)) _torneo(context, t, recargar),
              const SeccionTitulo('Próximos partidos'),
              if (p.proximos.isEmpty)
                const TarjetaBase(child: EstadoVacio(icono: Icons.event_busy_outlined, mensaje: 'No hay partidos programados. Programa uno desde el calendario de un torneo.'))
              else
                for (final partido in p.proximos) PartidoTile(partido: partido, mostrarFecha: true, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => EventDetailPage(eventoId: partido.id)))),
              const SeccionTitulo('Herramientas'),
              TarjetaBase(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ScoutPage())),
                child: const Row(children: [
                  Icon(Icons.smart_toy_outlined, color: AppColors.secondary, size: 28),
                  SizedBox(width: 14),
                  Expanded(child: Text('Scout AI: reportes y recomendaciones', style: TextStyle(color: AppColors.textWhite, fontWeight: FontWeight.bold))),
                  Icon(Icons.chevron_right, color: AppColors.textGray),
                ]),
              ),
            ],
          ),
        ),
      );

  Widget _alerta(IconData icono, String titulo, String detalle, Color color, VoidCallback onTap) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: TarjetaBase(
          onTap: onTap,
          child: Row(children: [
            Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: color.withValues(alpha: 0.15), shape: BoxShape.circle), child: Icon(icono, color: color)),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(titulo, style: const TextStyle(color: AppColors.textWhite, fontWeight: FontWeight.bold)),
              Text(detalle, style: const TextStyle(fontSize: 12, color: AppColors.textGray)),
            ])),
            const Icon(Icons.chevron_right, color: AppColors.textGray),
          ]),
        ),
      );

  Widget _torneo(BuildContext context, TorneoGestionado t, Future<void> Function() recargar) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: TarjetaBase(
          onTap: () async {
            await Navigator.push(context, MaterialPageRoute(builder: (_) => TorneoPage(torneoId: t.torneo.id, nombre: t.torneo.nombre)));
            await recargar();
          },
          child: Row(children: [
            AnilloProgreso(valor: t.avance, texto: '${(t.avance * 100).round()}%', color: AppColors.success, tamano: 54),
            const SizedBox(width: 14),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(t.torneo.nombre, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 15, color: AppColors.textWhite, fontWeight: FontWeight.bold)),
                const SizedBox(height: 2),
                Text('${t.equiposAceptados}/${t.torneo.maxEquipos == 0 ? '-' : t.torneo.maxEquipos} equipos · ${t.partidosJugados}/${t.partidosTotal} partidos', style: const TextStyle(fontSize: 12, color: AppColors.textGray)),
                const SizedBox(height: 6),
                Wrap(spacing: 6, children: [
                  TournamentChip(t.torneo.estado, color: colorEstado(t.torneo.estado)),
                  if (t.equiposPendientes > 0) TournamentChip('${t.equiposPendientes} por resolver', color: AppColors.warning),
                ]),
              ]),
            ),
          ]),
        ),
      );
}
