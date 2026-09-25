import 'package:flutter/material.dart';
import '../core/app_colors.dart';

class ProfileHeader extends StatelessWidget {
  final String initials;
  final String name;
  final String location;
  final List<String> badges;
  final VoidCallback onEditTap;

  const ProfileHeader({
    Key? key,
    required this.initials,
    required this.name,
    required this.location,
    required this.badges,
    required this.onEditTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Botón Editar
        Align(
          alignment: Alignment.centerRight,
          child: GestureDetector(
            onTap: onEditTap,
            child: const Text(
              'Editar Perfil',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.secondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Avatar + Info
        Row(
          children: [
            // Avatar circular
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  initials,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textWhite,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),

            // Nombre y ubicación
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textWhite,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    location,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.secondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Badges
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: badges
              .asMap()
              .entries
              .map((entry) {
                final index = entry.key;
                final badge = entry.value;
                final colors = [
                  const Color(0xFF10B981), // Verde (Verificado)
                  AppColors.secondary, // Cyan (Amateur)
                  const Color(0xFFF59E0B), // Naranja (Top)
                ];
                return _buildBadge(badge, colors[index % colors.length]);
              })
              .toList(),
        ),
      ],
    );
  }

  Widget _buildBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: AppColors.bgDark,
        ),
      ),
    );
  }
}