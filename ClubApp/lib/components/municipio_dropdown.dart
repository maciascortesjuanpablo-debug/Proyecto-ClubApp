import 'package:flutter/material.dart';
import '../core/app_colors.dart';
import '../core/colombia_municipios.dart';

/// Desplegable de municipios: muestra los del departamento elegido y queda deshabilitado mientras no haya uno.
/// Tiene el mismo aspecto que CityDropdown para que se vean como un par.
class MunicipioDropdown extends StatelessWidget {
  final String? departamento;
  final String? selected;
  final ValueChanged<String?> onChanged;

  const MunicipioDropdown({super.key, required this.departamento, required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final municipios = municipiosPorDepartamento[departamento] ?? const <String>[];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.bgCardLight),
      ),
      child: DropdownButton<String>(
        value: municipios.contains(selected) ? selected : null,
        isExpanded: true,
        underline: const SizedBox(),
        dropdownColor: AppColors.bgCard,
        menuMaxHeight: 320, // los departamentos grandes tienen más de 100 municipios: la lista se desplaza
        style: const TextStyle(color: AppColors.textWhite, fontSize: 14, fontWeight: FontWeight.w500),
        hint: Text(departamento == null ? 'Primero elige el departamento' : 'Selecciona el municipio', style: const TextStyle(color: AppColors.textGrayDark)),
        onChanged: municipios.isEmpty ? null : onChanged, // sin departamento, el desplegable no se abre

        items: [for (final m in municipios) DropdownMenuItem<String>(value: m, child: Text(m))],
      ),
    );
  }
}