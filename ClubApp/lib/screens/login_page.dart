import 'package:flutter/material.dart';
import '../core/app_colors.dart';
import '../core/validators.dart';
import '../components/app_header.dart';
import '../components/app_text_field.dart';
import '../components/app_button.dart';
import '../components/divider_with_text.dart';
import '../components/social_button.dart';
import '../components/navigation_link.dart';
import 'register_page_1.dart';
import 'home_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _login() {
    if (_formKey.currentState?.validate() ?? false) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomePage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 40),

                AppHeader(
                  title: 'CLUBAPP',
                  subtitle: 'Tu plataforma deportiva',
                  logoAssetPath: 'assets/images/logo1.png',
                  logoSize: 150,
                ),

                const SizedBox(height: 40),

                // Email Field
                AppTextField(
                  label: 'Correo Electrónico',
                  hint: 'tu@email.com',
                  controller: _emailController,
                  validator: AppValidators.validateEmail,
                ),

                const SizedBox(height: 16),

                // Password Field
                AppTextField(
                  label: 'Contraseña',
                  hint: '••••••••',
                  controller: _passwordController,
                  obscureText: true,
                  showVisibilityToggle: true,
                  validator: AppValidators.validatePassword,
                ),

                const SizedBox(height: 12),

                // Forgot Password Link
                Align(
                  alignment: Alignment.centerRight,
                  child: NavigationLink(
                    normalText: '¿Olvidaste tu contraseña?',
                    actionText: '',
                    onTap: () {},
                  ),
                ),

                const SizedBox(height: 24),

                // Login Button
                AppButton(
                  label: 'Iniciar Sesión',
                  onPressed: _login,
                ),

                const SizedBox(height: 24),

                // Divider
                const DividerWithText(text: 'O continúa con'),

                const SizedBox(height: 16),

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

                const SizedBox(height: 24),

                // Sign Up Link
                NavigationLink(
                  normalText: '¿No tienes cuenta? ',
                  actionText: 'Regístrate',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const RegisterPage1()),
                    );
                  },
                ),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}