import 'package:flutter/material.dart';
import '../core/navigation.dart';
import '../screens/google_profile_page.dart';
import '../services/auth_service.dart';
import 'app_dialogs.dart';
import 'social_button.dart';

/// "Continuar con Google": inicia sesión (o crea la cuenta) y entra a la app
class GoogleSignInButton extends StatefulWidget {
  const GoogleSignInButton({super.key});

  @override
  State<GoogleSignInButton> createState() => _GoogleSignInButtonState();
}

class _GoogleSignInButtonState extends State<GoogleSignInButton> {
  bool _cargando = false;

  Future<void> _entrar() async {
    setState(() => _cargando = true);
    final r = await AuthService.iniciarSesionConGoogle();
    if (!mounted) return;
    setState(() => _cargando = false);

    if (r['cancelado'] == true) return; // cerró el selector de cuentas
    if (r['exito'] != true) return mostrarError(context, r['mensaje'].toString());

    if (r['nuevo'] == true) {
      // Cuenta nueva: elige su rol antes de entrar
      Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const GoogleProfilePage()), (_) => false);
    } else {
      irAInicio(context);

    }
  }

  @override
  Widget build(BuildContext context) => _cargando
      ? const SizedBox(height: 48, child: Center(child: CircularProgressIndicator()))
      : SocialButton(icon: 'G', label: 'Continuar con Google', onPressed: _entrar);
}