import 'package:flutter/material.dart';

/// Icono grande dentro de un recuadro de color (cabecera de las pantallas de recuperación)
class IconBadge extends StatelessWidget {
  final IconData icon;
  final Color color;
  final Color iconColor;
  final double size;
  final double iconSize;
  final double radius;

  const IconBadge({
    super.key,
    required this.icon,
    required this.color,
    required this.iconColor,
    this.size = 100,
    this.iconSize = 80,
    this.radius = 16,
  });

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(radius)),
        child: Icon(icon, color: iconColor, size: iconSize),
      );
}
