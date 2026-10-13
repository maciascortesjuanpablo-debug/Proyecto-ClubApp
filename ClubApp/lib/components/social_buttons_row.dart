import 'package:flutter/material.dart';
import 'social_button.dart';

/// Botones de Google y Facebook (el acceso con redes sociales aún no está habilitado)
class SocialButtonsRow extends StatelessWidget {
  const SocialButtonsRow({super.key});

  void _pronto(BuildContext context) =>
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Próximamente')));

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Expanded(child: SocialButton(icon: 'G', label: 'Google', onPressed: () => _pronto(context))),
          const SizedBox(width: 12),
          Expanded(child: SocialButton(icon: 'f', label: 'Facebook', onPressed: () => _pronto(context))),
        ],
      );
}
