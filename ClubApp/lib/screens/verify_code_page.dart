import 'package:flutter/material.dart';
import '../core/app_colors.dart';
import '../components/code_verification_view.dart';
import '../services/auth_service.dart';
import 'new_password_page.dart';

/// Recuperar contraseña, paso 2: código enviado al correo
class VerifyCodePage extends StatelessWidget {
  final String email;

  const VerifyCodePage({super.key, required this.email});

  @override
  Widget build(BuildContext context) => CodeVerificationView(
        icon: Icons.mail_outline,
        color: AppColors.success,
        title: 'Revisa tu correo',
        subtitle: 'Enviamos un código de 6 dígitos a\n$email',
        buttonLabel: 'Verificar Código',
        nota: 'Por tu seguridad, el código expira\nen 10 minutos',
        onBack: () => Navigator.pop(context),
        onVerify: (codigo) async {
          final r = await AuthService.verificarCodigoRecuperacion(correo: email, codigo: codigo);
          if (r['exito'] != true) return r['mensaje'].toString();
          if (!context.mounted) return null;
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => NewPasswordPage(tokenTemporal: r['tokenTemporal'])));
          return null;
        },
        onResend: () async {
          final r = await AuthService.enviarCodigoRecuperacion(correo: email);
          return r['exito'] == true ? null : r['mensaje'].toString();
        },

      );
}