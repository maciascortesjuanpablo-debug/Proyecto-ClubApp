import 'package:flutter/material.dart';
import '../../components/standings_table.dart';
import '../../components/ui_kit.dart';
import '../../core/app_colors.dart';
import '../../models/models.dart';
import '../../services/tournament_service.dart';

/// Tabla de posiciones del torneo (los equipos propios van resaltados)
class TorneoPosicionesTab extends StatelessWidget {
  final Object torneoId;
  final Set<String> mios;
  const TorneoPosicionesTab({super.key, required this.torneoId, this.mios = const {}});

  @override
  Widget build(BuildContext context) => CargadorLista<List<FilaPosicion>>(
        cargar: () => TournamentService.tabla(torneoId),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
        construir: (_, filas, __) => [
          TablaPosiciones(filas: filas, resaltar: mios),
          const SizedBox(height: 14),
          const Text('PJ partidos jugados · G ganados · E empatados · P perdidos · DG diferencia de goles · PTS puntos', style: TextStyle(fontSize: 11, color: AppColors.textGrayDark)),
        ],
      );
}
