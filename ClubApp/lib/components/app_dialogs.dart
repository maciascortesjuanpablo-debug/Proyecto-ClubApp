import 'package:flutter/material.dart';
import '../core/app_colors.dart';
import '../screens/login_page.dart';
import '../services/auth_service.dart';

AlertDialog _dialogo(String titulo, String mensaje, List<Widget> acciones) => AlertDialog(
      backgroundColor: AppColors.bgCard,
      title: Text(titulo, style: const TextStyle(color: AppColors.textWhite)),
      content: Text(mensaje, style: const TextStyle(color: AppColors.textGray)),
      actions: acciones,
    );

Future<void> mostrarError(BuildContext context, String mensaje, {String titulo = 'Error'}) => showDialog(
      context: context,
      builder: (c) => _dialogo(titulo, mensaje, [TextButton(onPressed: () => Navigator.pop(c), child: const Text('Cerrar'))]),
    );

/// Devuelve true si hay sesión. Si es invitado, muestra el aviso y devuelve false.
/// Uso: if (!requireAuth(context)) return;
bool requireAuth(BuildContext context) {
  if (AuthService.isLoggedIn) return true;
  showDialog(
    context: context,
    builder: (c) => _dialogo('Inicia sesión', 'Necesitas una cuenta para realizar esta acción', [
      TextButton(onPressed: () => Navigator.pop(c), child: const Text('Cancelar')),
      TextButton(
        onPressed: () {
          Navigator.pop(c);
          Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginPage()));
        },
        child: const Text('Iniciar sesión'),
      ),
    ]),
  );
  return false;
}
