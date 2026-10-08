import 'package:ClubApp/screens/login_page.dart';
import 'package:flutter/material.dart';
import '../core/app_colors.dart';
import '../components/app_button.dart';
import '../components/app_text_field.dart';
import '../components/back_button_widget.dart';
import '../services/auth_service.dart';
import '../components/password_strength_bar.dart';

class NewPasswordPage extends StatefulWidget {
  final String tokenTemporal;

  const NewPasswordPage({Key? key, required this.tokenTemporal}) : super(key: key);

  @override
  State<NewPasswordPage> createState() => _NewPasswordPageState();
}

class _NewPasswordPageState extends State<NewPasswordPage> {
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _showSuccess = false;
  bool _isLoading = false;

  void _savePassword() async {
    if (_passwordController.text.isEmpty || _confirmController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Completa todos los campos')));
      return;
    }
    if (_passwordController.text != _confirmController.text) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Las contraseñas no coinciden')));
      return;
    }
    if (_passwordController.text.length < 8) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('La contraseña debe tener mínimo 8 caracteres')));
      return;
    }

    setState(() => _isLoading = true);

    final resultado = await AuthService.cambiarPasswordConToken(
      tokenTemporal: widget.tokenTemporal,
      nuevaPassword: _passwordController.text,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (resultado['exito']) {
      setState(() => _showSuccess = true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(resultado['mensaje'])),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      body: SafeArea(
        child: _showSuccess
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(color: AppColors.success.withOpacity(0.2), borderRadius: BorderRadius.circular(60)),
                      child: const Icon(Icons.check_circle_outline, color: AppColors.success, size: 80),
                    ),
                    const SizedBox(height: 24),
                    const Text('¡Contraseña Actualizada!', style: TextStyle(color: AppColors.textWhite, fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    const Text('Ya puedes iniciar sesión con tu nueva contraseña', textAlign: TextAlign.center, style: TextStyle(color: AppColors.textGray, fontSize: 14)),
                    const SizedBox(height: 32),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: AppButton(
                        label: 'Ir al Inicio de Sesión',
                        onPressed: () => Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(builder: (context) => const LoginPage()),
                          (route) => false,
                        ),
                      ),
                    ),
                  ],
                ),
              )
            : SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Align(alignment: Alignment.centerLeft, child: BackButtonWidget(onPressed: () => Navigator.pop(context))),
                    const SizedBox(height: 32),
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(color: AppColors.primaryLight.withOpacity(0.2), borderRadius: BorderRadius.circular(24)),
                      child: const Icon(Icons.lock_outline, color: AppColors.primaryLight, size: 50),
                    ),
                    const SizedBox(height: 24),
                    const Text('Nueva Contraseña', style: TextStyle(color: AppColors.textWhite, fontSize: 24, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    const Text('Elige una contraseña segura', style: TextStyle(color: AppColors.textGray, fontSize: 14)),
                    const SizedBox(height: 32),
                    AppTextField(label: 'Nueva Contraseña', hint: '••••••••', controller: _passwordController, obscureText: true, showVisibilityToggle: true),
                    const SizedBox(height: 16),
                    PasswordStrengthBar(password: _passwordController.text, label: 'Fortaleza'),
                    const SizedBox(height: 24),
                    AppTextField(label: 'Confirmar contraseña', hint: '••••••••', controller: _confirmController, obscureText: true, showVisibilityToggle: true),
                    const SizedBox(height: 32),
                    AppButton(label: 'Guardar Contraseña', onPressed: _savePassword, isLoading: _isLoading),
                  ],
                ),
              ),
      ),
    );
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }
}