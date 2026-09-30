import 'package:flutter/material.dart';
import '../core/app_colors.dart';
import 'app_card.dart';

/// Tabla genérica: 1ª columna angosta (#), 2ª expandida (nombre), el resto de 40 px.
class StatsTable extends StatelessWidget {
  final List<String> headers;
  final List<List<String>> rows;
  const StatsTable({super.key, required this.headers, required this.rows});

  @override
  Widget build(BuildContext context) {
    Widget row(List<String> cells, {bool head = false}) {
      final st = Theme.of(context).textTheme.bodySmall?.copyWith(
        color: head ? AppColors.textGrayDark : AppColors.textWhite,
        fontWeight: head ? FontWeight.w600 : FontWeight.normal,
      );
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(children: [
          for (var i = 0; i < cells.length; i++)
            i == 1
                ? Expanded(child: Text(cells[i], style: st))
                : SizedBox(width: i == 0 ? 24 : 40, child: Text(cells[i], style: st, textAlign: i == 0 ? TextAlign.start : TextAlign.center)),
        ]),
      );
    }

    return AppCard(child: Column(children: [row(headers, head: true), ...rows.map(row)]));
  }
}