import 'package:flutter/material.dart';
import '../core/app_colors.dart';
import '../core/calendar_utils.dart';

/// Cuadrícula de un mes (semana desde el lunes). Marca los días con eventos con puntos.
class MonthGrid extends StatelessWidget {
  final DateTime mes; // cualquier día del mes a mostrar
  final DateTime seleccionado;
  final Map<String, int> eventosPorDia; // 'AAAA-MM-DD' -> cantidad
  final ValueChanged<DateTime> onSeleccionar;

  const MonthGrid({super.key, required this.mes, required this.seleccionado, required this.eventosPorDia, required this.onSeleccionar});

  @override
  Widget build(BuildContext context) {
    final desfase = DateTime(mes.year, mes.month, 1).weekday - 1; // lunes = 0
    final dias = DateUtils.getDaysInMonth(mes.year, mes.month);
    final celdas = ((desfase + dias) / 7).ceil() * 7;
    final hoy = DateTime.now();
    return Column(children: [
      Row(children: [for (final d in diasSemana) Expanded(child: Center(child: Text(d, style: const TextStyle(fontSize: 11, color: AppColors.textGray, fontWeight: FontWeight.bold))))]),
      const SizedBox(height: 6),
      GridView.count(
        crossAxisCount: 7,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        childAspectRatio: 1.05,
        children: [
          for (var i = 0; i < celdas; i++)
            (i < desfase || i >= desfase + dias) ? const SizedBox.shrink() : _celda(DateTime(mes.year, mes.month, i - desfase + 1), hoy),
        ],
      ),
    ]);
  }

  Widget _celda(DateTime dia, DateTime hoy) {
    final elegido = DateUtils.isSameDay(dia, seleccionado);
    final esHoy = DateUtils.isSameDay(dia, hoy);
    final cantidad = eventosPorDia[isoFecha(dia)] ?? 0;
    return GestureDetector(
      onTap: () => onSeleccionar(dia),
      child: Container(
        margin: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: elegido ? AppColors.blue : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: esHoy && !elegido ? Border.all(color: AppColors.secondary) : null,
        ),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Text('${dia.day}', style: TextStyle(fontSize: 14, color: AppColors.textWhite, fontWeight: elegido || esHoy ? FontWeight.bold : FontWeight.w500)),
          const SizedBox(height: 3),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            for (var k = 0; k < (cantidad > 3 ? 3 : cantidad); k++)
              Container(width: 5, height: 5, margin: const EdgeInsets.symmetric(horizontal: 1), decoration: BoxDecoration(color: elegido ? AppColors.textWhite : AppColors.success, shape: BoxShape.circle)),
          ]),
        ]),
      ),
    );
  }
}