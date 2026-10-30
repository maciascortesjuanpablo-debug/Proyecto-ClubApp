import 'json_utils.dart';

class PuntoMes {
  final String mes; // AAAA-MM
  final int total;
  const PuntoMes(this.mes, this.total);
}

class TorneoGoles {
  final String nombre;
  final int goles, partidos;
  const TorneoGoles(this.nombre, this.goles, this.partidos);
}

Map<String, int> _conteos(dynamic v) => toMap(v).map((k, x) => MapEntry(k, toInt(x)));

/// Cifras del panel de administración
class AdminResumen {
  final int usuarios, usuariosActivos, usuariosNuevos7d;
  final Map<String, int> usuariosPorRol; // clave = id del rol
  final int torneos;
  final Map<String, int> torneosPorEstado;
  final int equipos, inscripcionesPendientes, partidos, partidosFinalizados, partidosEnVivo, goles;
  final List<PuntoMes> usuariosPorMes;
  final Map<String, int> partidosPorEstado, inscripcionesPorEstado;
  final List<TorneoGoles> golesPorTorneo;

  const AdminResumen({
    this.usuarios = 0,
    this.usuariosActivos = 0,
    this.usuariosNuevos7d = 0,
    this.usuariosPorRol = const {},
    this.torneos = 0,
    this.torneosPorEstado = const {},
    this.equipos = 0,
    this.inscripcionesPendientes = 0,
    this.partidos = 0,
    this.partidosFinalizados = 0,
    this.partidosEnVivo = 0,
    this.goles = 0,
    this.usuariosPorMes = const [],
    this.partidosPorEstado = const {},
    this.inscripcionesPorEstado = const {},
    this.golesPorTorneo = const [],
  });

  factory AdminResumen.fromJson(Map<String, dynamic> j) {
    final u = toMap(j['usuarios']);
    final t = toMap(j['torneos']);
    final p = toMap(j['partidos']);
    final s = toMap(j['series']);
    return AdminResumen(
      usuarios: toInt(u['total']),
      usuariosActivos: toInt(u['activos']),
      usuariosNuevos7d: toInt(u['nuevos7d']),
      usuariosPorRol: _conteos(u['porRol']),
      torneos: toInt(t['total']),
      torneosPorEstado: _conteos(t['porEstado']),
      equipos: toInt(j['equipos']),
      inscripcionesPendientes: toInt(j['inscripcionesPendientes']),
      partidos: toInt(p['total']),
      partidosFinalizados: toInt(p['finalizados']),
      partidosEnVivo: toInt(p['enVivo']),
      goles: toInt(j['goles']),
      usuariosPorMes: toLista(s['usuariosPorMes']).map((e) => PuntoMes(toStr(e['mes']), toInt(e['total']))).toList(),
      partidosPorEstado: _conteos(s['partidosPorEstado']),
      inscripcionesPorEstado: _conteos(s['inscripcionesPorEstado']),
      golesPorTorneo: toLista(s['golesPorTorneo']).map((e) => TorneoGoles(toStr(e['nombre']), toInt(e['goles']), toInt(e['partidos']))).toList(),
    );
  }

  double get promedioGoles => partidosFinalizados == 0 ? 0 : goles / partidosFinalizados;
  double get porcentajeActivos => usuarios == 0 ? 0 : usuariosActivos / usuarios;
}
