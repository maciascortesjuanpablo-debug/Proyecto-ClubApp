import '../screens/forgot_password_page.dart';
import 'package:flutter/material.dart';
import '../core/app_colors.dart';
import '../core/validators.dart';
import '../components/app_header.dart';
import '../components/app_text_field.dart';
import '../components/app_button.dart';
import '../components/divider_with_text.dart';
import '../components/social_button.dart';
import '../components/navigation_link.dart';
import '../components/success_dialog.dart';
import '../services/auth_service.dart';
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
  bool _cargando = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _cargando = true);

    final resultado = await AuthService.iniciarSesion(
      correo: _emailController.text.trim(),
      password: _passwordController.text,
    );

    if (!mounted) return;
    setState(() => _cargando = false);

    if (resultado['exito']) {
      final nombre = AuthService.usuario?['nombre'] ?? '';
      await SuccessDialog.show(
        context: context,
        title: '¡Bienvenido de nuevo!',
        message: nombre.isNotEmpty ? 'Hola de nuevo, $nombre' : 'Inicio de sesión exitoso',
        buttonText: 'Continuar',
        onButtonPressed: () {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const HomePage()),
          );
        },
      );
    } else {
      showDialog(
        context: context,
        builder: (c) => AlertDialog(
          backgroundColor: const Color(0xFF1E293B),
          title: const Text('Error', style: TextStyle(color: Colors.white)),
          content: Text(resultado['mensaje'], style: const TextStyle(color: Color(0xFF94A3B8))),
          actions: [
            TextButton(onPressed: () => Navigator.pop(c), child: const Text('Cerrar')),
          ],
        ),
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

                AppTextField(
                  label: 'Correo Electrónico',
                  hint: 'tu@email.com',
                  controller: _emailController,
                  validator: AppValidators.validateEmail,
                ),

                const SizedBox(height: 16),

                AppTextField(
                  label: 'Contraseña',
                  hint: '••••••••',
                  controller: _passwordController,
                  obscureText: true,
                  showVisibilityToggle: true,
                  validator: AppValidators.validatePassword,
                ),

                const SizedBox(height: 12),

                Align(
                  alignment: Alignment.centerRight,
                  child: NavigationLink(
                    normalText: '',
                    actionText: '¿Olvidaste tu contraseña?',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ForgotPasswordPage(),
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 24),

                AppButton(
                  label: _cargando ? 'Ingresando...' : 'Iniciar Sesión',
                  onPressed: _cargando ? () {} : _login,
                ),

                const SizedBox(height: 24),

                const DividerWithText(text: 'O continúa con'),

                const SizedBox(height: 16),

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