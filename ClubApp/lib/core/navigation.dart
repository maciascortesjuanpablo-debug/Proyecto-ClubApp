import 'package:flutter/material.dart';
import '../screens/login_page.dart';
import '../screens/main_shell.dart';

/// Va al inicio de la app y borra el resto del historial (tras iniciar sesión o registrarse)
void irAInicio(BuildContext context) =>
    Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const MainShell()), (_) => false);

/// Va al login y borra el historial (al cerrar sesión)
void irALogin(BuildContext context) =>
    Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const LoginPage()), (_) => false);
