import 'package:flutter/material.dart';
import '../core/app_colors.dart';
import '../core/validators.dart';

class PasswordStrengthBar extends StatelessWidget {
  final String password;
  final String label;

  const PasswordStrengthBar({super.key, required this.password, this.label = 'Fortaleza'});

  static const _colores = [AppColors.error, AppColors.error, AppColors.orange, AppColors.secondaryLight, AppColors.success];
  static const _textos = ['Débil', 'Débil', 'Media', 'Buena', 'Fuerte'];

  @override
  Widget build(BuildContext context) {
    final puntaje = AppValidators.checkPasswordStrength(password).puntaje; // misma política que el registro
    final color = _colores[puntaje];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(color: AppColors.textGray, fontSize: 13, fontWeight: FontWeight.w500)),
            if (password.isNotEmpty) Text(_textos[puntaje], style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w600)),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: List.generate(
            4,
            (i) => Expanded(
              child: Container(
                height: 6,
                margin: EdgeInsets.only(right: i < 3 ? 4 : 0),
                decoration: BoxDecoration(color: i < puntaje ? color : AppColors.bgCard, borderRadius: BorderRadius.circular(4)),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
