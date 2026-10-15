import 'package:flutter/material.dart';
import '../core/app_colors.dart';
import '../core/navigation.dart';
import '../core/validators.dart';
import '../components/app_button.dart';
import '../components/app_dialogs.dart';
import '../components/app_header.dart';
import '../components/app_text_field.dart';
import '../components/divider_with_text.dart';
import '../components/navigation_link.dart';
import '../components/social_buttons_row.dart';
import '../components/success_dialog.dart';
import '../services/auth_service.dart';
import 'forgot_password_page.dart';
import 'register_page_1.dart';
import 'two_factor_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

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

  final resultado = await AuthService.iniciarSesion(correo: _emailController.text.trim(), password: _passwordController.text);

  if (!mounted) return;
  setState(() => _cargando = false);

  if (resultado['exito'] != true) return mostrarError(context, resultado['mensaje']);

  // Contraseña correcta: falta confirmar con el código que llegó al correo
if (resultado['requiere2fa'] == true) {
  Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => TwoFactorPage(tokenDesafio: resultado['tokenDesafio'] as String, correo: resultado['correo'] as String)),
  );
  return;
}

  final nombre = AuthService.usuario?['nombre'] ?? '';
  await SuccessDialog.show(
    context: context,
    title: '¡Bienvenido de nuevo!',
    message: nombre.isNotEmpty ? 'Hola de nuevo, $nombre' : 'Inicio de sesión exitoso',
    onButtonPressed: () => irAInicio(context),
  );
}

  void _ir(Widget pagina) => Navigator.push(context, MaterialPageRoute(builder: (_) => pagina));

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
              children: [
                const SizedBox(height: 40),
                const AppHeader(title: 'CLUBAPP', subtitle: 'Tu plataforma deportiva', logoAssetPath: 'assets/images/logo1.png', logoSize: 150),
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
                  // En el login solo se exige que no esté vacía (la política de contraseñas aplica al crearla)
                  validator: (v) => AppValidators.validateRequired(v, 'La contraseña es requerida'),
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: NavigationLink(normalText: '', actionText: '¿Olvidaste tu contraseña?', onTap: () => _ir(const ForgotPasswordPage())),
                ),
                const SizedBox(height: 24),
                AppButton(label: 'Iniciar Sesión', isLoading: _cargando, onPressed: _login),
                const SizedBox(height: 24),
                const DividerWithText(text: 'O continúa con'),
                const SizedBox(height: 16),
                const SocialButtonsRow(),
                const SizedBox(height: 24),
                NavigationLink(normalText: '¿No tienes cuenta? ', actionText: 'Regístrate', onTap: () => _ir(const RegisterPage1())),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () => irAInicio(context),
                  child: const Text('Continuar como invitado', style: TextStyle(color: AppColors.textGray)),
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
