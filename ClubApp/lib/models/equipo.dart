import 'package:flutter/painting.dart';
import 'json_utils.dart';
import 'torneo.dart';

/// Equipo (tabla `equipos`). Según desde dónde se pida trae además datos de quien lo consulta
/// (su posición y dorsal si es jugador) o del equipo (cantidad de jugadores, inscripciones).
class Equipo {
  final Object id;
  final String nombre;
  final String? logoUrl;
  final Object? creadoPor;
  final int jugadores;
  // Solo para un jugador: su lugar dentro del equipo
  final String? posicion;
  final int? dorsal;
  final bool esTitular;
  // Solo para el entrenador: en qué torneos está inscrito
  final List<Inscripcion> inscripciones;
  // Ficha del equipo
  final String? eslogan;
  final String? descripcion;
  final String? ciudad;
  final String? formato; // Fútbol 11, Fútbol 7, Fútbol 5, Fútbol sala
  final String? formacion; // 4-4-2
  final int? maxJugadores;
  final String? colorPrincipal; // #RRGGBB

  const Equipo({
    required this.id,
    required this.nombre,
    this.logoUrl,
    this.creadoPor,
    this.jugadores = 0,
    this.posicion,
    this.dorsal,
    this.esTitular = false,
    this.inscripciones = const [],
    this.eslogan,
    this.descripcion,
    this.ciudad,
    this.formato,
    this.formacion,
    this.maxJugadores,
    this.colorPrincipal,
  });

  factory Equipo.fromJson(Map<String, dynamic> j) => Equipo(
        id: (j['id'] ?? '') as Object,
        nombre: toStr(j['nombre']),
        logoUrl: toStrN(j['logo_url']),
        creadoPor: j['creado_por'] as Object?,
        jugadores: toInt(j['jugadores']),
        posicion: toStrN(j['posicion']),
        dorsal: j['dorsal'] == null ? null : toInt(j['dorsal']),
        esTitular: toBool(j['es_titular']),
        inscripciones: toLista(j['inscripciones']).map(Inscripcion.fromJson).toList(),
        eslogan: toStrN(j['eslogan']),
        descripcion: toStrN(j['descripcion']),
        ciudad: toStrN(j['ciudad']),
        formato: toStrN(j['formato']),
        formacion: toStrN(j['formacion']),
        maxJugadores: j['max_jugadores'] == null ? null : toInt(j['max_jugadores']),
        colorPrincipal: toStrN(j['color_principal']),
      );

  String get iniciales => inicialesDe(nombre);

  /// Color del equipo (o el azul de la app si no eligió uno)
  Color get color => colorDesdeHex(colorPrincipal) ?? const Color(0xFF1E88E5);
}

/// "#1E88E5" -> Color; null si no es válido
Color? colorDesdeHex(String? hex) {
  if (hex == null || !RegExp(r'^#[0-9a-fA-F]{6}$').hasMatch(hex)) return null;
  return Color(0xFF000000 | int.parse(hex.substring(1), radix: 16));
}

String colorAHex(Color c) => '#${(c.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}';

/// Un jugador dentro de la plantilla de un equipo (tabla `equipo_jugadores`)
class JugadorPlantilla {
  final Object id;
  final Object? usuarioId;
  final String nombre;
  final String apellido;
  final String posicion;
  final int? dorsal;
  final String estado;
  final bool esTitular;
  final int? slotCampo; // casilla que ocupa en el campo (null = suplente)

  const JugadorPlantilla({required this.id, this.usuarioId, required this.nombre, required this.apellido, required this.posicion, this.dorsal, this.estado = '', this.esTitular = false, this.slotCampo});

  factory JugadorPlantilla.fromJson(Map<String, dynamic> j) {
    final u = toMap(j['usuarios']);
    return JugadorPlantilla(
      id: (j['id'] ?? '') as Object,
      usuarioId: u['id'] as Object?,
      nombre: toStr(u['nombre']),
      apellido: toStr(u['apellido']),
      posicion: toStr(j['posicion'], 'Sin asignar'),
      dorsal: j['dorsal'] == null ? null : toInt(j['dorsal']),
      estado: toStr(j['estado_convocatoria']),
      esTitular: toBool(j['es_titular']),
      slotCampo: j['slot_campo'] == null ? null : toInt(j['slot_campo']),
    );
  }

  String get nombreCompleto => '$nombre $apellido'.trim();
  String get iniciales => inicialesDe(nombre, apellido);
}

/// Integrante del cuerpo técnico (tabla `equipo_staff`)
class MiembroStaff {
  final Object id;
  final Object? usuarioId;
  final String nombre;
  final String cargo;

  const MiembroStaff({required this.id, this.usuarioId, required this.nombre, required this.cargo});

  factory MiembroStaff.fromJson(Map<String, dynamic> j) {
    final u = toMap(j['usuarios']);
    return MiembroStaff(id: (j['id'] ?? '') as Object, usuarioId: u['id'] as Object?, nombre: '${toStr(u['nombre'])} ${toStr(u['apellido'])}'.trim(), cargo: toStr(j['cargo'], 'Staff'));
  }
}

/// Invitación de un equipo a un jugador (tabla `invitaciones_equipo`)
class Invitacion {
  final Object id;
  final Equipo? equipo;
  final String? posicionPropuesta;

  const Invitacion({required this.id, this.equipo, this.posicionPropuesta});

  factory Invitacion.fromJson(Map<String, dynamic> j) =>
      Invitacion(id: (j['id'] ?? '') as Object, equipo: j['equipos'] is Map ? Equipo.fromJson(toMap(j['equipos'])) : null, posicionPropuesta: toStrN(j['posicion_propuesta']));
}

/// Jugador encontrado al buscar para invitarlo a un equipo
class JugadorBuscado {
  final Object id;
  final String nombre;
  final String apellido;
  final String? ciudad;
  final String? nivel;
  final String? posicion;

  const JugadorBuscado({required this.id, required this.nombre, required this.apellido, this.ciudad, this.nivel, this.posicion});

  factory JugadorBuscado.fromJson(Map<String, dynamic> j) => JugadorBuscado(
        id: (j['id'] ?? '') as Object,
        nombre: toStr(j['nombre']),
        apellido: toStr(j['apellido']),
        ciudad: toStrN(j['ciudad']),
        nivel: toStrN(j['nivel_juego']),
        posicion: toStrN(j['posicion']),
      );

  String get nombreCompleto => '$nombre $apellido'.trim();
}

/// Balance de un equipo (partidos jugados, ganados, empatados, perdidos y goles)
class BalanceEquipo {
  final int pj, g, e, p, gf, gc;
  const BalanceEquipo({this.pj = 0, this.g = 0, this.e = 0, this.p = 0, this.gf = 0, this.gc = 0});

  factory BalanceEquipo.fromJson(Map<String, dynamic> j) =>
      BalanceEquipo(pj: toInt(j['pj']), g: toInt(j['g']), e: toInt(j['e']), p: toInt(j['p']), gf: toInt(j['gf']), gc: toInt(j['gc']));

  int get puntos => g * 3 + e;
}