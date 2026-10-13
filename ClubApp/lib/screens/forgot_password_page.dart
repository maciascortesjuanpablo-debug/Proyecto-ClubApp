import 'package:flutter/material.dart';
import '../core/app_colors.dart';
import '../core/validators.dart';
import '../components/app_button.dart';
import '../components/app_text_field.dart';
import '../components/back_button_widget.dart';
import '../components/icon_badge.dart';
import '../services/auth_service.dart';
import 'verify_code_page.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _cargando = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _sendCode() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _cargando = true);

    final correo = _emailController.text.trim();
    final resultado = await AuthService.enviarCodigoRecuperacion(correo: correo);

    if (!mounted) return;
    setState(() => _cargando = false);

    if (resultado['exito'] == true) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => VerifyCodePage(email: correo)));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(resultado['mensaje'])));
    }
  }

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                BackButtonWidget(onPressed: () => Navigator.pop(context)),
                const SizedBox(height: 40),
                const IconBadge(icon: Icons.mail_outline, color: AppColors.primaryLight, iconColor: AppColors.textWhite),
                const SizedBox(height: 32),
                Text('¿Olvidaste tu contraseña?',
                    style: textos.headlineSmall?.copyWith(color: AppColors.textWhite, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                const SizedBox(height: 12),
                Text('Ingresa tu correo y te enviaremos\nun código de verificación',
                    style: textos.bodySmall?.copyWith(color: AppColors.textGray, fontSize: 15), textAlign: TextAlign.center),
                const SizedBox(height: 32),
                AppTextField(label: 'Correo Electrónico', hint: 'tu@email.com', controller: _emailController, validator: AppValidators.validateEmail),
                const SizedBox(height: 32),
                AppButton(label: 'Enviar código', isLoading: _cargando, onPressed: _sendCode),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.secondary),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Cancelar', style: TextStyle(color: AppColors.secondary, fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
