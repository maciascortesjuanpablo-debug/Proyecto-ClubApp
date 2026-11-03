import 'package:flutter/material.dart';
import '../core/app_colors.dart';
import 'json_utils.dart';

/// Notificación de la persona (tabla `notificaciones`)
class Notificacion {
  final Object id;
  final String titulo;
  final String tipo; // partido, resultado, designacion, torneo, invitacion, equipo, general
  final String? referenciaId; // id del partido o torneo al que apunta
  final bool leida;
  final DateTime creadoEn;

  const Notificacion({required this.id, required this.titulo, this.tipo = 'general', this.referenciaId, this.leida = false, required this.creadoEn});

  factory Notificacion.fromJson(Map<String, dynamic> j) => Notificacion(
        id: (j['id'] ?? '') as Object,
        titulo: toStr(j['titulo']),
        tipo: toStr(j['tipo'], 'general'),
        referenciaId: toStrN(j['referencia_id']),
        leida: toBool(j['leida']),
        creadoEn: DateTime.tryParse(toStr(j['creado_en']))?.toLocal() ?? DateTime.now(),
      );

  Notificacion copiarLeida() => Notificacion(id: id, titulo: titulo, tipo: tipo, referenciaId: referenciaId, leida: true, creadoEn: creadoEn);

  IconData get icono => switch (tipo) {
        'partido' => Icons.event_rounded,
        'resultado' => Icons.scoreboard_rounded,
        'designacion' => Icons.sports_score_rounded,
        'torneo' => Icons.emoji_events_rounded,
        'invitacion' => Icons.mail_rounded,
        'equipo' => Icons.groups_rounded,
        _ => Icons.notifications_rounded,
      };

  Color get color => switch (tipo) {
        'partido' => AppColors.primaryLight,
        'resultado' => AppColors.success,
        'designacion' => AppColors.warning,
        'torneo' => AppColors.secondary,
        'invitacion' => AppColors.orange,
        'equipo' => AppColors.orange,
        _ => AppColors.textGray,
      };

  /// "Ahora", "hace 5 min", "hace 3 h", "hace 2 d" o la fecha
  String get hace {
    final d = DateTime.now().difference(creadoEn);
    if (d.inMinutes < 1) return 'Ahora';
    if (d.inMinutes < 60) return 'hace ${d.inMinutes} min';
    if (d.inHours < 24) return 'hace ${d.inHours} h';
    if (d.inDays < 7) return 'hace ${d.inDays} d';
    return '${creadoEn.day.toString().padLeft(2, '0')}/${creadoEn.month.toString().padLeft(2, '0')}/${creadoEn.year}';
  }

  /// AAAA-MM-DD local, para agrupar por día
  String get dia => '${creadoEn.year}-${creadoEn.month.toString().padLeft(2, '0')}-${creadoEn.day.toString().padLeft(2, '0')}';
}