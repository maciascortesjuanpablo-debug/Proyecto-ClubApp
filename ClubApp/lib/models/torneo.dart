import 'equipo.dart';
import 'json_utils.dart';

/// Torneo (tabla `torneos`)
class Torneo {
  final Object id;
  final String nombre;
  final String estado;
  final String deporte;
  final String formato;
  final String? ciudad;
  final int maxEquipos;
  final int jornadaActual;
  final int? jornadaTotal;
  final Object? organizadorId;
  final String organizador;
  final DateTime? creadoEn;

  const Torneo({
    required this.id,
    required this.nombre,
    this.estado = 'Sin estado',
    this.deporte = '',
    this.formato = '',
    this.ciudad,
    this.maxEquipos = 0,
    this.jornadaActual = 0,
    this.jornadaTotal,
    this.organizadorId,
    this.organizador = '',
    this.creadoEn,
  });

  factory Torneo.fromJson(Map<String, dynamic> j) {
    final org = toMap(j['usuarios']);
    return Torneo(
      id: (j['id'] ?? '') as Object,
      nombre: toStr(j['nombre']),
      estado: toStr(j['estado'], 'Sin estado'),
      deporte: toStr(toMap(j['deportes'])['nombre']),
      formato: toStr(toMap(j['formatos'])['nombre']),
      ciudad: toStrN(j['ciudad']),
      maxEquipos: toInt(j['max_equipos']),
      jornadaActual: toInt(j['jornada_actual']),
      jornadaTotal: j['jornada_total'] == null ? null : toInt(j['jornada_total']),
      organizadorId: j['organizador_id'] as Object?,
      organizador: '${toStr(org['nombre'])} ${toStr(org['apellido'])}'.trim(),
      creadoEn: DateTime.tryParse(toStr(j['creado_en']))?.toLocal(),
    );
  }

  bool get cerrado => estado == 'Finalizado' || estado == 'Cancelado';
}

/// Inscripción de un equipo a un torneo (tabla `inscripciones_equipo`)
class Inscripcion {
  final Object id;
  final String estado; // Pendiente, Aceptado, Rechazado
  final DateTime? fecha;
  final Equipo? equipo;
  final Torneo? torneo;

  const Inscripcion({required this.id, required this.estado, this.fecha, this.equipo, this.torneo});

  factory Inscripcion.fromJson(Map<String, dynamic> j) {
    final eq = j['equipos'] ?? j['equipo'];
    final to = j['torneo'] ?? j['torneos'];
    return Inscripcion(
      id: (j['id'] ?? '') as Object,
      estado: toStr(j['estado'], 'Pendiente'),
      fecha: toFecha(j['fecha_inscripcion']),
      equipo: eq is Map ? Equipo.fromJson(toMap(eq)) : null,
      torneo: to is Map ? Torneo.fromJson(toMap(to)) : null,
    );
  }
}
