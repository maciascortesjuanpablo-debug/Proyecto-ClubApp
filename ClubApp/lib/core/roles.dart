import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'app_colors.dart';

/// Roles de la app (ids de la tabla `roles`). Cada rol tiene su propio conjunto de pantallas:
/// una vez elegido, la persona solo entra a lo que le corresponde (ver RoleGuard).
enum RolApp {
  usuario(1, 'Usuario', Icons.person_outline, AppColors.textGray),
  jugador(2, 'Jugador', Icons.sports_soccer, AppColors.success),
  entrenador(3, 'Entrenador', Icons.sports, AppColors.orange),
  organizador(4, 'Organizador', Icons.emoji_events, AppColors.primaryLight),
  arbitro(5, 'Árbitro', Icons.sports_score, AppColors.warning),
  admin(6, 'Administrador', Icons.admin_panel_settings, AppColors.secondary);

  const RolApp(this.id, this.nombre, this.icono, this.color);

  final int id;
  final String nombre;
  final IconData icono;
  final Color color;

  static RolApp deId(Object? id) {
    final n = id is num ? id.toInt() : int.tryParse('$id');
    return RolApp.values.firstWhere((r) => r.id == n, orElse: () => RolApp.usuario);
  }

  /// Rol de la sesión actual (invitado = usuario)
  static RolApp get actual => deId(AuthService.usuario?['rol_id']);

  /// Crean y administran torneos
  bool get gestionaTorneos => this == organizador || this == admin;

  /// Crean y administran equipos
  bool get gestionaEquipos => this == entrenador || this == admin;

  /// Tienen estadísticas personales de juego (goles, asistencias...)
  bool get tieneEstadisticasDeJuego => this == jugador;
}
