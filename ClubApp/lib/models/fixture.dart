import 'json_utils.dart';

/// Un partido que generaría el fixture automático (todavía no está guardado)
class PartidoPropuesto {
  final int jornada;
  final String? fase; // Grupo A, Ida, Vuelta, Cuartos de final...
  final DateTime? fecha;
  final String hora;
  final String local;
  final String visitante;
  final String? sede;

  const PartidoPropuesto({required this.jornada, this.fase, this.fecha, required this.hora, required this.local, required this.visitante, this.sede});

  factory PartidoPropuesto.fromJson(Map<String, dynamic> j) => PartidoPropuesto(
        jornada: toInt(j['jornada']),
        fase: toStrN(j['fase']),
        fecha: toFecha(j['fecha']),
        hora: toStr(j['hora']),
        local: toStr(toMap(j['local'])['nombre'], 'Por definir'),
        visitante: toStr(toMap(j['visitante'])['nombre'], 'Por definir'),
        sede: toStrN(j['sede']),
      );
}

class GrupoPropuesto {
  final String nombre;
  final List<String> equipos;
  const GrupoPropuesto(this.nombre, this.equipos);
}

/// Vista previa del calendario que se crearía: partidos, jornadas, fechas y avisos
class PropuestaFixture {
  final int total;
  final int jornadas;
  final DateTime? primera;
  final DateTime? ultima;
  final List<GrupoPropuesto> grupos;
  final List<String> descansan; // equipos que pasan directo (eliminación)
  final List<PartidoPropuesto> partidos;
  final int reemplazables; // partidos ya programados en el torneo
  final int bloqueantes; // partidos en juego o finalizados
  final List<String> advertencias;
  final bool puedeCrear;

  const PropuestaFixture({
    this.total = 0,
    this.jornadas = 0,
    this.primera,
    this.ultima,
    this.grupos = const [],
    this.descansan = const [],
    this.partidos = const [],
    this.reemplazables = 0,
    this.bloqueantes = 0,
    this.advertencias = const [],
    this.puedeCrear = false,
  });

  factory PropuestaFixture.fromJson(Map<String, dynamic> j) {
    final r = toMap(j['resumen']);
    final ex = toMap(j['existentes']);
    return PropuestaFixture(
      total: toInt(r['total']),
      jornadas: toInt(r['jornadas']),
      primera: toFecha(r['primera']),
      ultima: toFecha(r['ultima']),
      grupos: toLista(r['grupos']).map((g) => GrupoPropuesto(toStr(g['nombre']), (g['equipos'] as List? ?? []).map((e) => '$e').toList())).toList(),
      descansan: (r['descansan'] as List? ?? []).map((e) => '$e').toList(),
      partidos: toLista(j['partidos']).map(PartidoPropuesto.fromJson).toList(),
      reemplazables: toInt(ex['reemplazables']),
      bloqueantes: toInt(ex['bloqueantes']),
      advertencias: (j['advertencias'] as List? ?? []).map((e) => '$e').toList(),
      puedeCrear: toBool(j['puede_crear']),
    );
  }
}