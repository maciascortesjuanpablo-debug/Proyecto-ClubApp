import 'package:flutter/material.dart';
import '../../components/partido_tile.dart';
import '../../components/ui_kit.dart';
import '../../core/app_colors.dart';
import '../../models/models.dart';
import '../../services/panel_service.dart';
import '../event_detail_page.dart';

/// Pestaña "Partidos" del ÁRBITRO: sus designaciones por dirigir y su historial.
/// Desde el detalle de cada partido registra el resultado.
class ArbitroPartidosPage extends StatelessWidget {
  const ArbitroPartidosPage({super.key});

  @override
  Widget build(BuildContext context) => DefaultTabController(
        length: 2,
        child: Scaffold(
          backgroundColor: AppColors.bgDark,
          appBar: AppBar(
            backgroundColor: AppColors.bgDark,
            elevation: 0,
            title: const Text('Mis partidos'),
            bottom: const TabBar(indicatorColor: AppColors.secondary, labelColor: AppColors.secondary, unselectedLabelColor: AppColors.textGray, tabs: [Tab(text: 'Por dirigir'), Tab(text: 'Historial')]),
          ),
          body: const TabBarView(children: [_Lista(historial: false), _Lista(historial: true)]),
        ),
      );
}

class _Lista extends StatelessWidget {
  final bool historial;
  const _Lista({required this.historial});

  @override
  Widget build(BuildContext context) => CargadorLista<PanelArbitro>(
        cargar: PanelService.arbitro,
        construir: (context, p, recargar) {
          final lista = historial ? p.recientes : [...p.hoy, ...p.proximos];
          if (lista.isEmpty) return [EstadoVacio(icono: historial ? Icons.history : Icons.event_busy_outlined, mensaje: historial ? 'Todavía no has dirigido partidos' : 'No tienes partidos por dirigir')];
          return [
            for (final partido in lista)
              PartidoTile(
                partido: partido,
                mostrarFecha: true,
                etiqueta: partido.rolArbitraje,
                onTap: () async {
                  await Navigator.push(context, MaterialPageRoute(builder: (_) => EventDetailPage(eventoId: partido.id)));
                  await recargar();
                },
              ),
          ];
        },
      );
}
