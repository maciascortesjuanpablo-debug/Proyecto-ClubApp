import 'package:flutter/material.dart';
import '../core/app_colors.dart';
import '../screens/login_page.dart';
import '../screens/register_page_1.dart';
import 'app_button.dart';

class LoginRequiredView extends StatelessWidget {
  final String titulo;
  final String mensaje;
  final IconData icono;

  const LoginRequiredView({
    super.key,
    required this.titulo,
    required this.mensaje,
    this.icono = Icons.lock_outline,
  });

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: AppColors.bgDark,
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(color: AppColors.primaryLight.withValues(alpha: 0.2), shape: BoxShape.circle),
                  child: Icon(icono, color: AppColors.primaryLight, size: 44),
                ),
                const SizedBox(height: 24),
                Text(titulo,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppColors.textWhite, fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text(mensaje,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppColors.textGray, fontSize: 14)),
                const SizedBox(height: 28),
                AppButton(
                  label: 'Iniciar sesión',
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginPage())),
                ),
                const SizedBox(height: 4),
                TextButton(
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterPage1())),
                  child: const Text('Crear cuenta', style: TextStyle(color: AppColors.secondary)),
                ),
              ]),
            ),
          ),
        ),
      );
}