import 'package:clubapp_frontend/screens/RegisterPage3.dart';
import 'package:flutter/material.dart';
import '../core/app_colors.dart';
import '../components/back_button_widget.dart';
import '../components/progress_bar.dart';
import '../components/app_text_field.dart';
import '../components/app_button.dart';
import '../components/form_section.dart';

class RegisterPage2 extends StatefulWidget {
  const RegisterPage2({Key? key}) : super(key: key);

  @override
  State<RegisterPage2> createState() => _RegisterPage2State();
}

class _RegisterPage2State extends State<RegisterPage2> {
  final TextEditingController _positionController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  String? _selectedRole;
  String _selectedLevel = 'Amateur Competitivo';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  BackButtonWidget(onPressed: () => Navigator.pop(context)),
                  const SizedBox(height: 24),
                  ProgressBar(
                    value: 0.66,
                    label: 'CREAR CUENTA - PASO 2 DE 3',
                  ),
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
                            color: AppColors.primaryLight.withOpacity(0.3),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.primaryLight,
                              width: 2,
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.person,
                                color: AppColors.primaryLight,
                                size: 50,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '+ Foto',
                                style: TextStyle(
                                  color: AppColors.primaryLight,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 28),
                      AppTextField(
                        label: 'Posición en el campo',
                        hint: 'Ej: Delantero, Portero...',
                        controller: _positionController,
                      ),
                      const SizedBox(height: 16),
                      AppTextField(
                        label: 'Ciudad',
                        hint: 'Tu ciudad',
                        controller: _cityController,
                      ),
                      const SizedBox(height: 24),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Rol en la Plataforma',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textWhite,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _buildRoleButton('Jugador', Icons.person_3, 0),
                              _buildRoleButton(
                                  'Entrenador', Icons.sports_score, 1),
                              _buildRoleButton('Organizador', Icons.groups, 2),
                              _buildRoleButton(
                                  'Árbitro', Icons.sports_score_outlined, 3),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Nivel de Juego',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textWhite,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: const Color(0xFF334155),
                              ),
                            ),
                            child: DropdownButton<String>(
                              value: _selectedLevel,
                              isExpanded: true,
                              underline: const SizedBox(),
                              dropdownColor: AppColors.bgCard,
                              onChanged: (String? newValue) {
                                setState(() {
                                  _selectedLevel =
                                      newValue ?? 'Amateur Competitivo';
                                });
                              },
                              items: [
                                'Principiante',
                                'Intermedio',
                                'Amateur Competitivo',
                                'Profesional',
                              ]
                                  .map<DropdownMenuItem<String>>(
                                      (String value) {
                                return DropdownMenuItem<String>(
                                  value: value,
                                  child: Text(
                                    value,
                                    style: const TextStyle(
                                      color: AppColors.textWhite,
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  AppButton(
                    label: 'Continuar',
                    onPressed: () {
                      if (_selectedRole == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Por favor selecciona un rol'),
                          ),
                        );
                        return;
                      }
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const RegisterPage3(),
                        ),
                      );
                    },
                    backgroundColor: AppColors.primaryLight,
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRoleButton(String label, IconData icon, int index) {
    bool isSelected = _selectedRole == label;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() => _selectedRole = label);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primaryLight.withOpacity(0.3)
                : AppColors.primary.withOpacity(0.3),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected
                  ? AppColors.primaryLight
                  : const Color(0xFF334155),
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: isSelected ? AppColors.primaryLight : AppColors.textGray,
                size: 24,
              ),
              const SizedBox(height: 6),
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  color: isSelected
                      ? AppColors.primaryLight
                      : AppColors.textGray,
                  fontWeight:
                      isSelected ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _positionController.dispose();
    _cityController.dispose();
    super.dispose();
  }
}