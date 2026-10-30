import 'package:flutter/material.dart';
import '../core/app_colors.dart';
import '../core/roles.dart';
import '../services/auth_service.dart';

/// Protege una pantalla: solo la ven los roles indicados. Cualquier otro rol (o un invitado) ve un aviso.
/// Es la barrera de la app; el backend vuelve a verificar el rol en cada petición.
class RoleGuard extends StatelessWidget {
  final Set<RolApp> roles;
  final Widget child;

  const RoleGuard({super.key, required this.roles, required this.child});

  @override
  Widget build(BuildContext context) {
    if (AuthService.isLoggedIn && roles.contains(RolApp.actual)) return child;
    final nombres = roles.map((r) => r.nombre.toLowerCase()).join(' / ');
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(backgroundColor: AppColors.bgDark, elevation: 0),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.lock_outline, size: 56, color: AppColors.textGrayDark),
            const SizedBox(height: 16),
            const Text('Sección no disponible', style: TextStyle(fontSize: 18, color: AppColors.textWhite, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('Esta pantalla es exclusiva para el rol $nombres.', textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textGray)),
          ]),
        ),
      ),
    );
  }
}
