import 'package:flutter/material.dart';
import '../../components/admin_widgets.dart';
import '../../components/partido_tile.dart';
import '../../components/ui_kit.dart';
import '../../core/app_colors.dart';
import '../../core/calendar_utils.dart';
import '../../models/models.dart';
import '../../services/tournament_service.dart';
import '../event_detail_page.dart';

/// Enfrentamientos del torneo agrupados por día, con filtro por estado
class TorneoPartidosTab extends StatefulWidget {
  final Object torneoId;
  final Set<String> mios;
  const TorneoPartidosTab({super.key, required this.torneoId, this.mios = const {}});

  @override
  State<TorneoPartidosTab> createState() => _TorneoPartidosTabState();
}

class _TorneoPartidosTabState extends State<TorneoPartidosTab> {
  String? _filtro; // null = todos

  bool _pasa(Partido p) => switch (_filtro) {
        'proximos' => !p.finalizado && p.estado != 'Cancelado' && !p.enVivo,
        'vivo' => p.enVivo,
        'jugados' => p.finalizado,
        _ => true,
      };

  bool _esMio(Partido p) => widget.mios.contains('${p.local?.id}') || widget.mios.contains('${p.visitante?.id}');

  @override
  Widget build(BuildContext context) => CargadorLista<List<Partido>>(
        cargar: () => TournamentService.eventos(widget.torneoId),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
        construir: (context, todos, recargar) {
          final partidos = todos.where((p) => p.esPartido).toList();
          final lista = partidos.where(_pasa).toList();
          if (_filtro == 'jugados') lista.sort((a, b) => '${b.diaIso} ${b.hora}'.compareTo('${a.diaIso} ${a.hora}'));
          final hijos = <Widget>[
            FiltroChips<String>(opciones: const {'Todos': null, 'Próximos': 'proximos', 'En vivo': 'vivo', 'Jugados': 'jugados'}, valor: _filtro, onChanged: (v) => setState(() => _filtro = v)),
            const SizedBox(height: 8),
          ];
          if (lista.isEmpty) {
            hijos.add(const EstadoVacio(icono: Icons.sports_score_outlined, mensaje: 'No hay partidos para mostrar'));
          }
          String? dia;
          for (final p in lista) {
            if (p.diaIso != dia) {
              dia = p.diaIso;
              hijos.add(Padding(
                padding: const EdgeInsets.only(top: 14, bottom: 8),
                child: Text(p.fecha == null ? 'Sin fecha' : fechaLarga(p.fecha!), style: const TextStyle(fontSize: 13, color: AppColors.secondary, fontWeight: FontWeight.bold)),
              ));
            }
            hijos.add(PartidoTile(
              partido: p,
              mostrarTorneo: false,
              etiqueta: _esMio(p) ? 'Mi equipo' : null,
              onTap: () async {
                await Navigator.push(context, MaterialPageRoute(builder: (_) => EventDetailPage(eventoId: p.id)));
                await recargar();
              },
            ));
          }
          return hijos;
        },
      );
}
