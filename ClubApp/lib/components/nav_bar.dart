import 'dart:ui';
import 'package:flutter/material.dart';
import '../core/app_colors.dart';

/// Una pestaña de la barra inferior
class NavDestino {
  final IconData icon;
  final String label;
  const NavDestino(this.icon, this.label);
}

/// Barra inferior flotante. Cada rol pasa sus propias pestañas en [items]; sin ellas muestra las generales.
class BottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;
  final List<NavDestino>? items;

  const BottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.items,
  });

  static const _generales = [
    NavDestino(Icons.home_rounded, 'Inicio'),
    NavDestino(Icons.emoji_events_rounded, 'Torneos'),
    NavDestino(Icons.person_rounded, 'Perfil'),
    NavDestino(Icons.calendar_month_rounded, 'Calendario'),
    NavDestino(Icons.smart_toy_outlined, 'Scout AI'),
  ];

  @override
  Widget build(BuildContext context) {
    final _items = items ?? _generales;
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(40),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              height: 68,
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.bgCard.withOpacity(0.7),
                borderRadius: BorderRadius.circular(40),
                border: Border.all(
                  color: Colors.white.withOpacity(0.12),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.25),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final itemWidth = constraints.maxWidth / _items.length;
                  return Stack(
                    children: [
                      // Cápsula indicadora animada
                      AnimatedPositioned(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeOutCubic,
                        left: itemWidth * currentIndex,
                        top: 0,
                        bottom: 0,
                        width: itemWidth,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.14),
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                      ),
                      // Ítems
                      Row(
                        children: List.generate(_items.length, (i) {
                          final selected = i == currentIndex;
                          final color = selected
                              ? AppColors.secondary
                              : AppColors.textGrayDark;
                          return Expanded(
                            child: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: () => onTap(i),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  AnimatedScale(
                                    scale: selected ? 1.1 : 1.0,
                                    duration:
                                        const Duration(milliseconds: 200),
                                    child: Icon(_items[i].icon,
                                        color: color, size: 24),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    _items[i].label,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: color,
                                      fontSize: 10,
                                      fontWeight: selected
                                          ? FontWeight.w600
                                          : FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
