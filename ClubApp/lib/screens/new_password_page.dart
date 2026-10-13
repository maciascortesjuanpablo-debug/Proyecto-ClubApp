import 'package:flutter/material.dart';
import '../core/app_colors.dart';
import '../core/navigation.dart';
import '../core/validators.dart';
import '../components/app_button.dart';
import '../components/app_text_field.dart';
import '../components/back_button_widget.dart';
import '../components/icon_badge.dart';
import '../components/password_strength_bar.dart';
import '../services/auth_service.dart';

class NewPasswordPage extends StatefulWidget {
  final String tokenTemporal;

  const NewPasswordPage({super.key, required this.tokenTemporal});

  @override
  State<NewPasswordPage> createState() => _NewPasswordPageState();
}

class _NewPasswordPageState extends State<NewPasswordPage> {
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _showSuccess = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  void _aviso(String texto) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(texto)));

  Future<void> _savePassword() async {
    // Misma política que el registro: 8 caracteres, mayúscula, número y carácter especial
    final error = AppValidators.validatePassword(_passwordController.text) ??
        AppValidators.validateConfirmPassword(_confirmController.text, _passwordController.text);
    if (error != null) return _aviso(error);

    setState(() => _isLoading = true);
    final resultado = await AuthService.cambiarPasswordConToken(tokenTemporal: widget.tokenTemporal, nuevaPassword: _passwordController.text);
    if (!mounted) return;
    setState(() => _isLoading = false);

    if (resultado['exito'] == true) {
      setState(() => _showSuccess = true);
    } else {
      _aviso(resultado['mensaje']);
    }
  }

  Widget get _exito => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconBadge(
              icon: Icons.check_circle_outline,
              color: AppColors.success.withValues(alpha: 0.2),
              iconColor: AppColors.success,
              size: 120,
              radius: 60,
            ),
            const SizedBox(height: 24),
            const Text('¡Contraseña Actualizada!', style: TextStyle(color: AppColors.textWhite, fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('Ya puedes iniciar sesión con tu nueva contraseña',
                textAlign: TextAlign.center, style: TextStyle(color: AppColors.textGray, fontSize: 14)),
            const SizedBox(height: 32),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: AppButton(label: 'Ir al Inicio de Sesión', onPressed: () => irALogin(context)),
            ),
          ],
        ),
      );

  Widget get _formulario => SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            BackButtonWidget(onPressed: () => Navigator.pop(context)),
            const SizedBox(height: 32),
            IconBadge(
              icon: Icons.lock_outline,
              color: AppColors.primaryLight.withValues(alpha: 0.2),
              iconColor: AppColors.primaryLight,
              iconSize: 50,
              radius: 24,
            ),
            const SizedBox(height: 24),
            const Text('Nueva Contraseña', style: TextStyle(color: AppColors.textWhite, fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('Elige una contraseña segura', style: TextStyle(color: AppColors.textGray, fontSize: 14)),
            const SizedBox(height: 32),
            AppTextField(
              label: 'Nueva Contraseña',
              hint: '••••••••',
              controller: _passwordController,
              obscureText: true,
              showVisibilityToggle: true,
              onChanged: (_) => setState(() {}), // actualiza la barra de fortaleza
            ),
            const SizedBox(height: 16),
            PasswordStrengthBar(password: _passwordController.text),
            const SizedBox(height: 24),
            AppTextField(label: 'Confirmar contraseña', hint: '••••••••', controller: _confirmController, obscureText: true, showVisibilityToggle: true),
            const SizedBox(height: 32),
            AppButton(label: 'Guardar Contraseña', onPressed: _savePassword, isLoading: _isLoading),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: AppColors.bgDark,
        body: SafeArea(child: _showSuccess ? _exito : _formulario),
      );
}
