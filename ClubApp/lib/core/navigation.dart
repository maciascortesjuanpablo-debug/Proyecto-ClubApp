import 'package:flutter/material.dart';
import '../screens/consentimiento_page.dart';
import '../screens/login_page.dart';
import '../services/auth_service.dart';
import '../screens/main_shell.dart';

/// Va al inicio de la app y borra el resto del historial (tras iniciar sesión o registrarse)
/// Si la cuenta aún no aceptó la versión vigente de los términos, pasa primero por ConsentimientoPage.
void irAInicio(BuildContext context) {
  final pendiente = AuthService.consentimientoPendiente != null;
  Navigator.pushAndRemoveUntil(
    context,
    MaterialPageRoute(builder: (_) => pendiente ? const ConsentimientoPage(alAceptar: irAInicio) : const MainShell()),
    (_) => false,
  );
}

/// Va al login y borra el historial (al cerrar sesión)
void irALogin(BuildContext context) =>
    Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const LoginPage()), (_) => false);
