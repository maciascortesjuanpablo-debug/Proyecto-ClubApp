import 'package:flutter/material.dart';
import '../core/app_colors.dart';
import '../core/perfil_constants.dart';

/// Botones para elegir el rol al crear la cuenta. `value` es el id del rol (tabla `roles`).
class RoleSelector extends StatelessWidget {
  final int? value;
  final ValueChanged<int> onChanged;

  const RoleSelector({super.key, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) => Row(children: [
        for (final e in rolesRegistro.entries) _boton(e.key, e.value.$1, e.value.$2),
      ]);

  Widget _boton(String etiqueta, IconData icono, int id) {
    final seleccionado = value == id;
    final color = seleccionado ? AppColors.primaryLight : AppColors.textGray;
    return Expanded(
      child: GestureDetector(
        onTap: () => onChanged(id),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: (seleccionado ? AppColors.primaryLight : AppColors.primary).withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: seleccionado ? AppColors.primaryLight : AppColors.bgCardLight, width: seleccionado ? 2 : 1),
          ),
          child: Column(children: [
            Icon(icono, color: color, size: 24),
            const SizedBox(height: 6),
            Text(etiqueta, textAlign: TextAlign.center, style: TextStyle(fontSize: 11, color: color, fontWeight: seleccionado ? FontWeight.w600 : FontWeight.w500)),
          ]),
        ),
      ),
    );
  }
}