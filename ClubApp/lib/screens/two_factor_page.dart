import 'package:flutter/material.dart';
import '../core/app_colors.dart';
import '../core/navigation.dart';
import '../components/code_verification_view.dart';
import '../components/success_dialog.dart';
import '../services/auth_service.dart';

/// Segundo paso del inicio de sesión: código de 6 dígitos enviado al correo
class TwoFactorPage extends StatelessWidget {
  final String tokenDesafio;
  final String correo; // ya viene enmascarado desde el backend (ju**@gmail.com)
  final String titulo;
  final String mensaje;
  final String? posicionPerfil; // al registrarse: perfil de jugador que se crea al verificar
  final bool desdeRegistro;

  const TwoFactorPage({
    super.key,
    required this.tokenDesafio,
    required this.correo,
    this.titulo = '¡Bienvenido de vuelta!',
    this.mensaje = 'Verificación exitosa',
    this.posicionPerfil,
    this.desdeRegistro = false,
  });

  @override
  Widget build(BuildContext context) => CodeVerificationView(
        icon: Icons.verified_user_outlined,
        color: AppColors.primaryLight,
        title: 'Verifica que eres tú',
        subtitle: 'Enviamos un código de 6 dígitos a\n$correo',

        buttonLabel: 'Verificar e ingresar',
        nota: 'Por tu seguridad, el código expira\nen 10 minutos',
        onBack: () => desdeRegistro ? irALogin(context) : Navigator.pop(context),
        onVerify: (codigo) async {
          final r = await AuthService.verificarDosPasos(tokenDesafio: tokenDesafio, codigo: codigo);
          if (r['exito'] != true) return r['mensaje'].toString();
          // Ya hay sesión: se puede crear el perfil de jugador pendiente del registro
          if (posicionPerfil?.isNotEmpty ?? false) await AuthService.crearPerfilJugador(posicion: posicionPerfil!);
          if (!context.mounted) return null;
          await SuccessDialog.show(context: context, title: titulo, message: mensaje, onButtonPressed: () => irAInicio(context));
          return null;
        },
        onResend: () async {
          final r = await AuthService.reenviarDosPasos(tokenDesafio: tokenDesafio);
          return r['exito'] == true ? null : r['mensaje'].toString();
        },
      );
}