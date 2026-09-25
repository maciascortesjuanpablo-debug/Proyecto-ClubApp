import 'package:flutter/material.dart';
import '../core/app_colors.dart';
import '../core/validators.dart';
import '../components/back_button_widget.dart';
import '../components/progress_bar.dart';
import '../components/form_section.dart';
import '../components/app_text_field.dart';
import '../components/app_button.dart';
import '../components/divider_with_text.dart';
import '../components/social_button.dart';
import '../components/navigation_link.dart';
import '../components/date_picker_field.dart';
import '../screens/register_page_2.dart';
import '../screens/login_page.dart';

class RegisterPage1 extends StatefulWidget {
  const RegisterPage1({Key? key}) : super(key: key);

  @override
  State<RegisterPage1> createState() => _RegisterPage1State();
}

class _RegisterPage1State extends State<RegisterPage1> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _lastnamesController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _birthdateController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _lastnamesController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _birthdateController.dispose();
    super.dispose();
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
                  width: 150,
                  height: 150,
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
                const ProgressBar(value: 0.33, label: 'Paso 1 de 3'),

                const SizedBox(height: 24),

                // Form Section
                FormSection(
                  title: 'Información Personal',
                  subtitle: 'Cuéntanos sobre ti',
                  children: [
                    // Name
                    AppTextField(
                      label: 'Nombre',
                      hint: 'Juan',
                      controller: _nameController,
                      validator: AppValidators.validateName,
                    ),
                    const SizedBox(height: 16),

                    // Lastnames
                    AppTextField(
                      label: 'Apellidos',
                      hint: 'Pérez García',
                      controller: _lastnamesController,
                      validator: AppValidators.validateLastNames,
                    ),
                    const SizedBox(height: 16),

                    // Email
                    AppTextField(
                      label: 'Correo Electrónico',
                      hint: 'tu@email.com',
                      controller: _emailController,
                      validator: AppValidators.validateEmail,
                    ),
                    const SizedBox(height: 16),

                    // Phone
                    AppTextField(
                      label: 'Celular',
                      hint: '+57 3001234567',
                      controller: _phoneController,
                      validator: AppValidators.validatePhone,
                    ),
                    const SizedBox(height: 16),

                    // Birthdate
                    DatePickerField(
                      label: 'Fecha de Nacimiento',
                      hint: 'DD/MM/YYYY',
                      controller: _birthdateController,
                      validator: AppValidators.validateDate,
                      initialDate: DateTime(2000),
                      firstDate: DateTime(1950),
                      lastDate: DateTime.now(),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Continue Button -> navega directo con MaterialPageRoute
                AppButton(
                  label: 'Continuar',
                  onPressed: () {
                    if (_formKey.currentState?.validate() ?? false) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const RegisterPage2(),
                        ),
                      );
                    }
                  },
                ),

                const SizedBox(height: 16),

                // Divider
                const DividerWithText(text: 'O regístrate con'),

                const SizedBox(height: 12),

                // Social Buttons
                Row(
                  children: [
                    Expanded(
                      child: SocialButton(
                        icon: 'G',
                        label: 'Google',
                        onPressed: () {},
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: SocialButton(
                        icon: 'f',
                        label: 'Facebook',
                        onPressed: () {},
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Login Link
                NavigationLink(
                  normalText: '¿Ya tienes cuenta? ',
                  actionText: 'Inicia Sesión',
                  onTap: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => const LoginPage()),
                    );
                  },
                ),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}