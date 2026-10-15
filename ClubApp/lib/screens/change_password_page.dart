import 'package:flutter/material.dart';
import '../core/app_colors.dart';
import '../core/validators.dart';
import '../components/app_button.dart';
import '../components/app_text_field.dart';
import '../components/password_strength_bar.dart';
import '../services/profile_service.dart';

class ChangePasswordPage extends StatefulWidget {
  const ChangePasswordPage({super.key});

  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _actual = TextEditingController();
  final _nueva = TextEditingController();
  final _confirmar = TextEditingController();
  bool _guardando = false;

  @override
  void dispose() {
    for (final c in [_actual, _nueva, _confirmar]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _guardar() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _guardando = true);

    final r = await ProfileService.cambiarPassword(actual: _actual.text, nueva: _nueva.text);
    if (!mounted) return;
    setState(() => _guardando = false);

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(r['exito'] == true ? 'Contraseña actualizada' : r['mensaje'].toString())));
    if (r['exito'] == true) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: AppColors.bgDark,
        appBar: AppBar(backgroundColor: AppColors.bgDark, elevation: 0, title: const Text('Cambiar contraseña')),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(children: [
                AppTextField(
                  label: 'Contraseña actual',
                  hint: '••••••••',
                  controller: _actual,
                  obscureText: true,
                  showVisibilityToggle: true,
                  validator: (v) => AppValidators.validateRequired(v, 'Ingresa tu contraseña actual'),
                ),
                const SizedBox(height: 20),
                AppTextField(
                  label: 'Nueva contraseña',
                  hint: '••••••••',

                  controller: _nueva,
                  obscureText: true,
                  showVisibilityToggle: true,
                  validator: AppValidators.validatePassword,
                  onChanged: (_) => setState(() {}), // actualiza la barra de fortaleza
                ),
                const SizedBox(height: 12),
                PasswordStrengthBar(password: _nueva.text),
                const SizedBox(height: 20),
                AppTextField(
                  label: 'Confirmar nueva contraseña',
                  hint: '••••••••',
                  controller: _confirmar,
                  obscureText: true,
                  showVisibilityToggle: true,
                  validator: (v) => AppValidators.validateConfirmPassword(v, _nueva.text),
                ),
                const SizedBox(height: 32),
                AppButton(label: 'Guardar contraseña', isLoading: _guardando, backgroundColor: AppColors.blue, onPressed: _guardar),
              ]),
            ),
          ),
        ),
      );
}