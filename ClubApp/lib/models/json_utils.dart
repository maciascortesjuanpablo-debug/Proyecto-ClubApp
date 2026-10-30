/// Lectura tolerante del JSON del backend: un campo ausente o de otro tipo nunca rompe la pantalla.
int toInt(dynamic v, [int porDefecto = 0]) => v is num ? v.toInt() : (int.tryParse('$v') ?? porDefecto);
double toDouble(dynamic v, [double porDefecto = 0]) => v is num ? v.toDouble() : (double.tryParse('$v') ?? porDefecto);
bool toBool(dynamic v, [bool porDefecto = false]) => v is bool ? v : porDefecto;
String toStr(dynamic v, [String porDefecto = '']) => v == null ? porDefecto : v.toString();
String? toStrN(dynamic v) {
  final s = v?.toString().trim();
  return (s == null || s.isEmpty) ? null : s;
}

/// Acepta "2026-11-05" o "2026-11-05T00:00:00"
DateTime? toFecha(dynamic v) {
  final s = v?.toString().split('T').first;
  return s == null ? null : DateTime.tryParse(s);
}

Map<String, dynamic> toMap(dynamic v) => v is Map ? Map<String, dynamic>.from(v) : <String, dynamic>{};
Map<String, dynamic>? toMapN(dynamic v) => v is Map ? Map<String, dynamic>.from(v) : null;
List<Map<String, dynamic>> toLista(dynamic v) => v is List ? v.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList() : <Map<String, dynamic>>[];

/// "Juan Pablo" + "Pérez" -> "JP"
String inicialesDe(String nombre, [String apellido = '']) {
  final partes = '$nombre $apellido'.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
  if (partes.isEmpty) return '?';
  if (partes.length == 1) return partes[0][0].toUpperCase();
  return (partes[0][0] + partes[1][0]).toUpperCase();
}
