import 'package:flutter/material.dart';
import '../../core/app_colors.dart';
import '../app_button.dart';

class GuestBanner extends StatelessWidget {
  final VoidCallback onLogin;
  final VoidCallback onRegister;

  const GuestBanner({super.key, required this.onLogin, required this.onRegister});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppColors.bgCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.secondary.withValues(alpha: 0.4)),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Únete a ClubApp',
                style: TextStyle(color: AppColors.textWhite, fontSize: 17, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            const Text('Crea torneos, arma tu equipo y sigue tus estadísticas.',
                style: TextStyle(color: AppColors.textGray, fontSize: 13)),
            const SizedBox(height: 14),
            AppButton(label: 'Iniciar sesión', onPressed: onLogin),
            Center(
              child: TextButton(
                onPressed: onRegister,
                child: const Text('Crear cuenta', style: TextStyle(color: AppColors.secondary)),
              ),
            ),
          ]),
        ),
      );
}