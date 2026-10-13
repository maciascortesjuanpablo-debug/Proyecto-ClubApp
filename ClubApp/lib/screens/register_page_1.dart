import 'package:flutter/material.dart';
import '../core/app_colors.dart';
import '../core/validators.dart';
import '../components/app_button.dart';
import '../components/app_header.dart';
import '../components/app_text_field.dart';
import '../components/back_button_widget.dart';
import '../components/date_picker_field.dart';
import '../components/divider_with_text.dart';
import '../components/form_section.dart';
import '../components/navigation_link.dart';
import '../components/progress_bar.dart';
import '../components/social_buttons_row.dart';
import 'login_page.dart';
import 'register_page_2.dart';

class RegisterPage1 extends StatefulWidget {
  const RegisterPage1({super.key});

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
    for (final c in [_nameController, _lastnamesController, _emailController, _phoneController, _birthdateController]) {
      c.dispose();
    }
    super.dispose();
  }

  void _continuar() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RegisterPage2(
          nombre: _nameController.text.trim(),
          apellido: _lastnamesController.text.trim(),
          correo: _emailController.text.trim(),
          celular: _phoneController.text.trim(),
          fechaNacimiento: _birthdateController.text.trim(), // formato DD/MM/YYYY
        ),
      ),
    );
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
                BackButtonWidget(onPressed: () => Navigator.pop(context)),
                const SizedBox(height: 16),
                const AppHeader(title: 'ClubApp', subtitle: 'Plataforma deportiva integral', logoAssetPath: 'assets/images/logo1.png', logoSize: 150),
                const SizedBox(height: 20),
                const ProgressBar(value: 0.33, label: 'Paso 1 de 3'),
                const SizedBox(height: 24),
                FormSection(
                  title: 'Información Personal',
                  subtitle: 'Cuéntanos sobre ti',
                  children: [
                    AppTextField(label: 'Nombre', hint: 'Juan Pablo', controller: _nameController, validator: AppValidators.validateName),
                    const SizedBox(height: 16),
                    AppTextField(label: 'Apellidos', hint: 'Triviño Bustos', controller: _lastnamesController, validator: AppValidators.validateLastNames),
                    const SizedBox(height: 16),
                    AppTextField(label: 'Correo Electrónico', hint: 'tu@email.com', controller: _emailController, validator: AppValidators.validateEmail),
                    const SizedBox(height: 16),
                    AppTextField(label: 'Celular', hint: '3001234567', controller: _phoneController, validator: AppValidators.validatePhone),
                    const SizedBox(height: 16),
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
                AppButton(label: 'Continuar', onPressed: _continuar),
                const SizedBox(height: 16),
                const DividerWithText(text: 'O regístrate con'),
                const SizedBox(height: 12),
                const SocialButtonsRow(),
                const SizedBox(height: 16),
                NavigationLink(
                  normalText: '¿Ya tienes cuenta? ',
                  actionText: 'Inicia Sesión',
                  onTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginPage())),
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
