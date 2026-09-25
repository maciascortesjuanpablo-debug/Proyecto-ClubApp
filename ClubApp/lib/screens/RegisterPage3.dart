import 'package:flutter/material.dart';
import '../core/app_colors.dart';
import '../core/validators.dart';
import '../components/back_button_widget.dart';
import '../components/progress_bar.dart';
import '../components/form_section.dart';
import '../components/app_text_field.dart';
import '../components/app_button.dart';

class RegisterPage3 extends StatefulWidget {
  const RegisterPage3({Key? key}) : super(key: key);

  @override
  State<RegisterPage3> createState() => _RegisterPage3State();
}

class _RegisterPage3State extends State<RegisterPage3> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _acceptTerms = false;
  late PasswordStrength _strength = PasswordStrength(
    hasMinChars: false,
    hasUpperCase: false,
    hasNumber: false,
    hasSpecialChar: false,
  );

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _validatePassword(String password) {
    setState(() {
      _strength = AppValidators.checkPasswordStrength(password);
    });
  }

  void _register() {
    if (_formKey.currentState?.validate() ?? false) {
      if (!_acceptTerms) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Debes aceptar los términos y condiciones')),
        );
        return;
      }

      if (!_strength.isStrong) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('La contraseña no cumple los requisitos')),
        );
        return;
      }

      Navigator.pushReplacementNamed(context, '/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                const SizedBox(height: 20),

                // Back Button
                Align(
                  alignment: Alignment.centerLeft,
                  child: BackButtonWidget(onPressed: () => Navigator.pop(context)),
                ),

                const SizedBox(height: 16),

                // Logo
                Container(
                  width: 200,
                  height: 200,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.asset(
                      'assets/images/logo1.png',
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return const Center(
                          child: Text(
                            'c',
                            style: TextStyle(
                              color: AppColors.textWhite,
                              fontSize: 40,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                const Text(
                  'ClubApp',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textWhite
                  ),
                ),
                const Text(
                  'Plataforma deportiva integral',
                  style: TextStyle(
                    fontSize: 18,
                    color: AppColors.textGray
                  ),
                ),

                const SizedBox(height: 20),

                // Progress Bar
                const ProgressBar(value: 1.0, label: 'Paso 3 de 3'),

                const SizedBox(height: 24),

                // Form Section
                FormSection(
                  title: 'Seguridad',
                  subtitle: 'Crea una contraseña fuerte',
                  children: [
                    // Password
                    AppTextField(
                      label: 'Contraseña',
                      hint: '••••••••',
                      controller: _passwordController,
                      obscureText: true,
                      showVisibilityToggle: true,
                      validator: AppValidators.validatePassword,
                      onChanged: _validatePassword, // <-- FIX: actualiza el checklist en tiempo real
                    ),

                    const SizedBox(height: 16),

                    // Confirm Password
                    AppTextField(
                      label: 'Confirmar Contraseña',
                      hint: '••••••••',
                      controller: _confirmPasswordController,
                      obscureText: true,
                      showVisibilityToggle: true,
                      validator: (v) => AppValidators.validateConfirmPassword(v, _passwordController.text),
                    ),

                    const SizedBox(height: 20),

                    // Requirements Card
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.bgCard,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.primaryLight.withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Requisitos de contraseña',
                            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                              color: AppColors.textWhite,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 12),
                          _buildRequirement('8 caracteres mínimo', _strength.hasMinChars),
                          const SizedBox(height: 8),
                          _buildRequirement('Una mayúscula', _strength.hasUpperCase),
                          const SizedBox(height: 8),
                          _buildRequirement('Un número', _strength.hasNumber),
                          const SizedBox(height: 8),
                          _buildRequirement('Un carácter especial', _strength.hasSpecialChar),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Terms Checkbox
                    Row(
                      children: [
                        Checkbox(
                          value: _acceptTerms,
                          onChanged: (value) {
                            setState(() {
                              _acceptTerms = value ?? false;
                            });
                          },
                          activeColor: AppColors.primaryLight,
                          checkColor: AppColors.textWhite,
                        ),
                        Expanded(
                          child: Text(
                            'Acepto los términos y condiciones',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textGray,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 32),

                // Register Button
                AppButton(
                  label: 'Crear mi cuenta',
                  onPressed: _register,
                ),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRequirement(String text, bool isValid) {
    return Row(
      children: [
        Icon(
          isValid ? Icons.check_circle : Icons.circle_outlined,
          size: 18,
          color: isValid ? AppColors.success : AppColors.textGrayDark,
        ),
        const SizedBox(width: 10),
        Text(
          text,
          style: TextStyle(
            fontSize: 13,
            color: isValid ? AppColors.success : AppColors.textGrayDark,
          ),
        ),
      ],
    );
  }
}