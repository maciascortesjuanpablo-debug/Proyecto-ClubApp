import 'package:flutter/material.dart';
import '../core/app_colors.dart';
import '../components/login_required_view.dart';
import '../services/auth_service.dart';

class ComingSoonPage extends StatelessWidget {
  final String titulo;
  final IconData icono;
  final bool requiereLogin;

  const ComingSoonPage({
    super.key,
    required this.titulo,
    required this.icono,
    this.requiereLogin = false,
  });

  @override
  Widget build(BuildContext context) {
    if (requiereLogin && AuthService.isGuest) {
      return LoginRequiredView(titulo: titulo, mensaje: 'Inicia sesión para acceder a $titulo', icono: icono);
    }
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      body: SafeArea(
        child: Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(icono, color: AppColors.textGray, size: 56),
            const SizedBox(height: 12),
            Text(titulo, style: const TextStyle(color: AppColors.textWhite, fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            const Text('Próximamente', style: TextStyle(color: AppColors.textGray)),
          ]),
        ),
      ),
    );
  }
}