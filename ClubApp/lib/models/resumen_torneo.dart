import 'json_utils.dart';
import 'partido.dart';
import 'torneo.dart';

class Goleador {
  final String nombre;
  final String equipo;
  final int goles;
  const Goleador({required this.nombre, required this.equipo, required this.goles});

  factory Goleador.fromJson(Map<String, dynamic> j) => Goleador(nombre: '${toStr(j['nombre'])} ${toStr(j['apellido'])}'.trim(), equipo: toStr(j['equipo']), goles: toInt(j['goles']));
}

/// Todo lo de la pestaña "Resumen" de un torneo
class ResumenTorneo {
  final Torneo torneo;
  final int equiposAceptados, equiposPendientes, equiposMax;
  final int partidosTotal, programados, enVivo, finalizados, aplazados, cancelados;
  final int golesTotal;
  final double golesPromedio;
  final String? lider;
  final int liderPuntos;
  final Partido? proximo;
  final Partido? ultimo;
  final List<Goleador> goleadores;

  const ResumenTorneo({
    required this.torneo,
    this.equiposAceptados = 0,
    this.equiposPendientes = 0,
    this.equiposMax = 0,
    this.partidosTotal = 0,
    this.programados = 0,
    this.enVivo = 0,
    this.finalizados = 0,
    this.aplazados = 0,
    this.cancelados = 0,
    this.golesTotal = 0,
    this.golesPromedio = 0,
    this.lider,
    this.liderPuntos = 0,
    this.proximo,
    this.ultimo,
    this.goleadores = const [],
  });

  factory ResumenTorneo.fromJson(Map<String, dynamic> j) {
    final eq = toMap(j['equipos']);
    final pa = toMap(j['partidos']);
    final go = toMap(j['goles']);
    final lider = toMapN(j['lider']);
    return ResumenTorneo(
      torneo: Torneo.fromJson(toMap(j['torneo'])),
      equiposAceptados: toInt(eq['aceptados']),
      equiposPendientes: toInt(eq['pendientes']),
      equiposMax: toInt(eq['max']),
      partidosTotal: toInt(pa['total']),
      programados: toInt(pa['programados']),
      enVivo: toInt(pa['enVivo']),
      finalizados: toInt(pa['finalizados']),
      aplazados: toInt(pa['aplazados']),
      cancelados: toInt(pa['cancelados']),
      golesTotal: toInt(go['total']),
      golesPromedio: toDouble(go['promedio']),
      lider: lider == null ? null : toStrN(toMap(lider['equipo'])['nombre']),
      liderPuntos: lider == null ? 0 : toInt(lider['puntos']),
      proximo: j['proximo'] is Map ? Partido.fromJson(toMap(j['proximo'])) : null,
      ultimo: j['ultimo'] is Map ? Partido.fromJson(toMap(j['ultimo'])) : null,
      goleadores: toLista(j['goleadores']).map(Goleador.fromJson).toList(),
    );
  }

  double get avance => partidosTotal == 0 ? 0 : finalizados / partidosTotal;
  double get ocupacion => equiposMax == 0 ? 0 : equiposAceptados / equiposMax;
}
