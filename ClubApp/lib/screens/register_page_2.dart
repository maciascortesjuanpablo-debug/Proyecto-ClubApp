import 'package:flutter/material.dart';
import '../core/app_colors.dart';
import '../components/app_button.dart';
import '../components/app_text_field.dart';
import '../components/back_button_widget.dart';
import '../components/citydrop_down.dart';
import '../components/form_section.dart';
import '../components/progress_bar.dart';
import 'register_page_3.dart';

// Rol visible -> (icono, id en la tabla `roles`)
const _roles = {
  'Jugador': (Icons.person_3, 2),
  'Entrenador': (Icons.sports_score, 3),
  'Organizador': (Icons.groups, 4),
  'Árbitro': (Icons.sports_score_outlined, 5),
};
const _niveles = ['Principiante', 'Intermedio', 'Amateur Competitivo', 'Profesional'];

class RegisterPage2 extends StatefulWidget {
  final String nombre;
  final String apellido;
  final String correo;
  final String celular;
  final String fechaNacimiento;

  const RegisterPage2({
    super.key,
    required this.nombre,
    required this.apellido,
    required this.correo,
    required this.celular,
    required this.fechaNacimiento,
  });

  @override
  State<RegisterPage2> createState() => _RegisterPage2State();
}

class _RegisterPage2State extends State<RegisterPage2> {
  final _positionController = TextEditingController();
  String? _selectedRole;
  String? _selectedCity;
  String _selectedLevel = 'Amateur Competitivo';

  @override
  void dispose() {
    _positionController.dispose();
    super.dispose();
  }

  void _aviso(String texto) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(texto)));

  void _continuar() {
    if (_selectedRole == null) return _aviso('Por favor selecciona un rol');
    if (_selectedCity == null) return _aviso('Por favor selecciona un departamento');
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RegisterPage3(
          nombre: widget.nombre,
          apellido: widget.apellido,
          correo: widget.correo,
          celular: widget.celular,
          fechaNacimiento: widget.fechaNacimiento,
          ciudad: _selectedCity!,
          posicion: _positionController.text.trim(),
          rolId: _roles[_selectedRole]!.$2,
          nivelJuego: _selectedLevel,
        ),
      ),
    );
  }

  Widget _campo(String titulo, Widget hijo, {double espacio = 10}) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(titulo, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textWhite)),
          SizedBox(height: espacio),
          hijo,
        ],
      );

  Widget _rolBoton(String label, IconData icon) {
    final seleccionado = _selectedRole == label;
    final color = seleccionado ? AppColors.primaryLight : AppColors.textGray;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedRole = label),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: (seleccionado ? AppColors.primaryLight : AppColors.primary).withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: seleccionado ? AppColors.primaryLight : AppColors.bgCardLight, width: seleccionado ? 2 : 1),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(height: 6),
              Text(label,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 11, color: color, fontWeight: seleccionado ? FontWeight.w600 : FontWeight.w500)),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                BackButtonWidget(onPressed: () => Navigator.pop(context)),
                const SizedBox(height: 24),
                const ProgressBar(value: 0.66, label: 'CREAR CUENTA - PASO 2 DE 3'),
                const SizedBox(height: 28),
                FormSection(
                  title: 'Tu perfil deportivo',
                  subtitle: 'Complétalo aquí',
                  children: [
                    Center(
                      child: Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight.withValues(alpha: 0.3),
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.primaryLight, width: 2),
                        ),
                        child: const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.person, color: AppColors.primaryLight, size: 50),
                            SizedBox(height: 4),
                            Text('+ Foto', style: TextStyle(color: AppColors.primaryLight, fontSize: 11, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),
                    AppTextField(label: 'Posición en el campo', hint: 'Ej: Delantero, Portero...', controller: _positionController),
                    const SizedBox(height: 16),
                    _campo('Departamento', CityDropdown(selectedCity: _selectedCity, onChanged: (city) => setState(() => _selectedCity = city))),
                    const SizedBox(height: 24),
                    _campo(
                      'Rol en la Plataforma',
                      Row(children: [for (final e in _roles.entries) _rolBoton(e.key, e.value.$1)]),
                      espacio: 12,
                    ),
                    const SizedBox(height: 24),
                    _campo(
                      'Nivel de Juego',
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.bgCardLight),
                        ),
                        child: DropdownButton<String>(
                          value: _selectedLevel,
                          isExpanded: true,
                          underline: const SizedBox(),
                          dropdownColor: AppColors.bgCard,
                          onChanged: (v) => setState(() => _selectedLevel = v ?? _selectedLevel),
                          items: [
                            for (final n in _niveles) DropdownMenuItem(value: n, child: Text(n, style: const TextStyle(color: AppColors.textWhite))),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                AppButton(label: 'Continuar', onPressed: _continuar, backgroundColor: AppColors.primaryLight),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
