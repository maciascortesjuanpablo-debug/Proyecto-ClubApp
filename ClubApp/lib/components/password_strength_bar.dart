import 'package:flutter/material.dart';
import '../core/app_colors.dart';

class PasswordStrengthBar extends StatelessWidget {
  final String password;
  final String label;

  const PasswordStrengthBar({
    Key? key,
    required this.password,
    this.label = 'Fortaleza',
  }) : super(key: key);

  int get _puntaje {
    int puntos = 0;
    if (password.length >= 8) puntos++;
    if (RegExp(r'[A-Z]').hasMatch(password)) puntos++;
    if (RegExp(r'[0-9]').hasMatch(password)) puntos++;
    if (RegExp(r'[!@#$%^&*(),.?":{}|<>_\-]').hasMatch(password)) puntos++;
    return puntos;
  }

  Color get _color {
    switch (_puntaje) {
      case 0:
      case 1:
        return const Color(0xFFEF4444); // rojo - débil
      case 2:
        return const Color(0xFFF59E0B); // amarillo - media
      case 3:
        return const Color(0xFF22D3EE); // cyan - buena
      default:
        return AppColors.success; // verde - fuerte
    }
  }

  String get _texto {
    switch (_puntaje) {
      case 0:
      case 1:
        return 'Débil';
      case 2:
        return 'Media';
      case 3:
        return 'Buena';
      default:
        return 'Fuerte';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(color: AppColors.textGray, fontSize: 13, fontWeight: FontWeight.w500),
            ),
            if (password.isNotEmpty)
              Text(
                _texto,
                style: TextStyle(color: _color, fontSize: 13, fontWeight: FontWeight.w600),
              ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Row(
            children: List.generate(4, (index) {
              final activo = index < _puntaje;
              return Expanded(
                child: Container(
                  height: 6,
                  margin: EdgeInsets.only(right: index < 3 ? 4 : 0),
                  decoration: BoxDecoration(
                    color: activo ? _color : AppColors.bgCard,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }
}