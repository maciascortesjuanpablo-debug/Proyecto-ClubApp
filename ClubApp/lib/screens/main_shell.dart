import 'package:flutter/material.dart';
import '../core/roles.dart';
import '../services/auth_service.dart';
import 'shell/general_shell.dart';
import 'shell/role_shells.dart';

/// Punto de entrada tras iniciar sesión. Elige la navegación según el rol de la sesión:
/// cada rol (jugador, entrenador, organizador, árbitro, administrador) tiene sus propias pantallas
/// y no puede entrar a las de otro. Invitados y cuentas sin rol usan la navegación general (solo consulta).
class MainShell extends StatelessWidget {
  final int initialIndex;
  const MainShell({super.key, this.initialIndex = 0});

  @override
  Widget build(BuildContext context) {
    if (AuthService.isGuest) return GeneralShell(initialIndex: initialIndex);
    return switch (RolApp.actual) {
      RolApp.jugador => JugadorShell(initialIndex: initialIndex),
      RolApp.entrenador => EntrenadorShell(initialIndex: initialIndex),
      RolApp.organizador => OrganizadorShell(initialIndex: initialIndex),
      RolApp.arbitro => ArbitroShell(initialIndex: initialIndex),
      RolApp.admin => AdminShell(initialIndex: initialIndex),
      RolApp.usuario => GeneralShell(initialIndex: initialIndex),
    };
  }
}
