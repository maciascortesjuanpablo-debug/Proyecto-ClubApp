import 'json_utils.dart';

/// Equipo tal como aparece dentro de un partido
class EquipoMini {
  final Object? id;
  final String nombre;
  final String? logoUrl;

  const EquipoMini({this.id, required this.nombre, this.logoUrl});

  static EquipoMini? desde(dynamic v) => v is Map ? EquipoMini(id: v['id'] as Object?, nombre: toStr(v['nombre'], 'Por definir'), logoUrl: toStrN(v['logo_url'])) : null;
}

/// Evento del calendario (tabla `eventos_calendario`): partido, entrenamiento, reunión...
class Partido {
  final Object id;
  final Object? torneoId;
  final String torneoNombre;
  final Object? organizadorId;
  final String tipo;
  final String estado;
  final DateTime? fecha;
  final String hora; // HH:MM
  final EquipoMini? local;
  final EquipoMini? visitante;
  final int? resultadoLocal;
  final int? resultadoVisitante;
  final Object? sedeId;
  final String? sede;
  final List<String> relacion; // equipo, arbitro, organizador
  final String? rolArbitraje; // solo en la vista del árbitro
  /// JSON original: las hojas de resultado y de árbitros trabajan con él
  final Map<String, dynamic> raw;

  const Partido({
    required this.id,
    this.torneoId,
    this.torneoNombre = '',
    this.organizadorId,
    this.tipo = 'Partido',
    this.estado = 'Programado',
    this.fecha,
    this.hora = '',
    this.local,
    this.visitante,
    this.resultadoLocal,
    this.resultadoVisitante,
    this.sedeId,
    this.sede,
    this.relacion = const [],
    this.rolArbitraje,
    this.raw = const {},
  });

  factory Partido.fromJson(Map<String, dynamic> j) {
    final h = toStr(j['hora']);
    final torneo = toMap(j['torneo']);
    return Partido(
      id: (j['id'] ?? '') as Object,
      torneoId: j['torneo_id'] as Object?,
      torneoNombre: toStr(torneo['nombre']),
      organizadorId: torneo['organizador_id'] as Object?,
      tipo: toStr(j['tipo'], 'Partido'),
      estado: toStr(j['estado'], 'Programado'),
      fecha: toFecha(j['fecha']),
      hora: h.length >= 5 ? h.substring(0, 5) : h,
      local: EquipoMini.desde(j['equipo_local']),
      visitante: EquipoMini.desde(j['equipo_visitante']),
      resultadoLocal: j['resultado_local'] == null ? null : toInt(j['resultado_local']),
      resultadoVisitante: j['resultado_visitante'] == null ? null : toInt(j['resultado_visitante']),
      sedeId: j['lugar_id'] as Object?,
      sede: toStrN(toMap(j['sedes_canchas'])['nombre']),
      relacion: (j['relacion'] is List) ? (j['relacion'] as List).map((e) => '$e').toList() : const [],
      rolArbitraje: toStrN(j['rol_arbitraje']),
      raw: j,
    );
  }

  bool get esPartido => tipo == 'Partido';
  bool get enVivo => estado == 'En vivo';
  bool get finalizado => estado == 'Finalizado';
  bool get tieneMarcador => resultadoLocal != null && resultadoVisitante != null;
  String get nombreLocal => local?.nombre ?? 'Por definir';
  String get nombreVisitante => visitante?.nombre ?? 'Por definir';

  /// Clave AAAA-MM-DD para agrupar por día
  String get diaIso => fecha == null ? '' : '${fecha!.year}-${fecha!.month.toString().padLeft(2, '0')}-${fecha!.day.toString().padLeft(2, '0')}';

  /// Resultado desde el punto de vista de un equipo: 'G', 'E', 'P' o null si no se ha jugado
  String? resultadoPara(Object equipoId) {
    if (!finalizado || !tieneMarcador) return null;
    final esLocal = '${local?.id}' == '$equipoId';
    final gf = esLocal ? resultadoLocal! : resultadoVisitante!;
    final gc = esLocal ? resultadoVisitante! : resultadoLocal!;
    return gf > gc ? 'G' : (gf == gc ? 'E' : 'P');
  }
}
