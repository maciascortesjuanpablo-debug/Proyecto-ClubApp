import 'package:flutter/material.dart';
import '../core/app_colors.dart';
import '../models/models.dart';
import '../services/team_service.dart';

/// Diálogo para cambiar posición, dorsal y si es titular un jugador de la plantilla. Devuelve true si se guardó algo.
Future<bool> editarJugadorEquipo(BuildContext context, Object equipoId, JugadorPlantilla j) async {
  if (j.usuarioId == null) return false;
  final dorsal = TextEditingController(text: j.dorsal?.toString() ?? '');
  final posicion = TextEditingController(text: j.posicion == 'Sin asignar' ? '' : j.posicion);
  final guardar = await showDialog<bool>(
    context: context,
    builder: (d) => AlertDialog(
      backgroundColor: AppColors.bgCard,
      title: Text(j.nombreCompleto, style: const TextStyle(color: AppColors.textWhite)),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: posicion, style: const TextStyle(color: AppColors.textWhite), decoration: const InputDecoration(labelText: 'Posición')),
        TextField(controller: dorsal, keyboardType: TextInputType.number, style: const TextStyle(color: AppColors.textWhite), decoration: const InputDecoration(labelText: 'Dorsal')),
      ]),
      actions: [TextButton(onPressed: () => Navigator.pop(d, false), child: const Text('Cancelar')), TextButton(onPressed: () => Navigator.pop(d, true), child: const Text('Guardar'))],
    ),
  );
  if (guardar != true) return false;
  final r = await TeamService.actualizarJugador(equipoId, j.usuarioId!, {
    if (posicion.text.trim().isNotEmpty) 'posicion': posicion.text.trim(),
    if (int.tryParse(dorsal.text.trim()) != null) 'dorsal': int.parse(dorsal.text.trim()),
  });
  if (!context.mounted) return false;
  if (r['exito'] != true) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(r['mensaje'].toString())));
  return r['exito'] == true;
}