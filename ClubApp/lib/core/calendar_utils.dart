import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'app_colors.dart';

const nombresMes = ['enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio', 'julio', 'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre'];
const _nombresDia = ['lunes', 'martes', 'miércoles', 'jueves', 'viernes', 'sábado', 'domingo'];
const diasSemana = ['L', 'M', 'X', 'J', 'V', 'S', 'D']; // la semana empieza en lunes

const estadosPartido = ['Programado', 'En vivo', 'Finalizado', 'Aplazado', 'Cancelado'];
const tiposEvento = ['Partido', 'Entrenamiento', 'Reunión', 'Otro'];

/// 2026-11-05
String isoFecha(DateTime d) => '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

/// Acepta "2026-11-05" o "2026-11-05T00:00:00"
DateTime? parseFecha(dynamic v) {
  final s = v?.toString().split('T').first;
  return s == null ? null : DateTime.tryParse(s);
}

/// "16:00:00" -> "16:00"
String horaCorta(dynamic h) {
  final s = h?.toString() ?? '';
  return s.length >= 5 ? s.substring(0, 5) : s;
}

/// "jueves 5 de noviembre"
String fechaLarga(DateTime d) => '${_nombresDia[d.weekday - 1]} ${d.day} de ${nombresMes[d.month - 1]}';

/// ¿El día es anterior a hoy? (esos días no admiten crear eventos)
bool diaPasado(DateTime d) => DateUtils.dateOnly(d).isBefore(DateUtils.dateOnly(DateTime.now()));

/// ¿Esa fecha y hora ya pasaron? La hora actual cuenta como pasada.
bool enElPasado(DateTime fecha, TimeOfDay hora) => !DateTime(fecha.year, fecha.month, fecha.day, hora.hour, hora.minute).isAfter(DateTime.now());

Color colorEstadoPartido(String estado) => switch (estado) {
      'En vivo' => AppColors.success,
      'Finalizado' => AppColors.textGrayDark,

      'Aplazado' => AppColors.warning,
      'Cancelado' => AppColors.error,
      _ => AppColors.primaryLight,
    };

// ---- Permisos en pantalla (el backend vuelve a verificarlos en cada petición) ----
String? get _miId => AuthService.usuario?['id']?.toString();
int? get miRol => (AuthService.usuario?['rol_id'] as num?)?.toInt();

/// Organizadores (4) y administradores (6) crean eventos
bool get puedeCrearEventos => miRol == 4 || miRol == 6;

/// Admin, o el organizador del torneo al que pertenece el evento
bool puedeGestionarEvento(Map<String, dynamic> evento) => miRol == 6 || (miRol == 4 && evento['torneo']?['organizador_id']?.toString() == _miId);

/// ¿Soy uno de los árbitros asignados a este evento?
bool soyArbitroDe(Map<String, dynamic> evento) => ((evento['arbitros'] as List?) ?? []).any((a) => a['usuarios']?['id']?.toString() == _miId);