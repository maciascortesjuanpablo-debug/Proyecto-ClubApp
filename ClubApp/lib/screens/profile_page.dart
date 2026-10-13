import 'package:flutter/material.dart';
import '../core/app_colors.dart';
import '../core/navigation.dart';
import '../components/app_button.dart';
import '../components/login_required_view.dart';
import '../services/auth_service.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    if (AuthService.isGuest) {
      return const LoginRequiredView(titulo: 'Mi Perfil', mensaje: 'Inicia sesión para ver tu perfil', icono: Icons.person);
    }
    final usuario = AuthService.usuario;
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(title: const Text('Mi Perfil'), backgroundColor: AppColors.bgDark, elevation: 0),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.person, color: AppColors.secondary, size: 80),
              const SizedBox(height: 16),
              Text('${usuario?['nombre'] ?? ''} ${usuario?['apellido'] ?? ''}'.trim(),
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textWhite)),
              const SizedBox(height: 4),
              Text(usuario?['correo'] ?? '', style: const TextStyle(fontSize: 14, color: AppColors.textGray)),
              const SizedBox(height: 32),
              AppButton(
                label: 'Cerrar sesión',
                backgroundColor: AppColors.error,
                onPressed: () async {
                  await AuthService.logout();
                  if (context.mounted) irALogin(context);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
