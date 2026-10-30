import '../core/roles.dart';
import 'json_utils.dart';

/// Datos de la cuenta de una persona (tabla `usuarios`)
class Usuario {
  final Object id;
  final String nombre;
  final String apellido;
  final String correo;
  final String? celular;
  final String? ciudad;
  final String? nivelJuego;
  final DateTime? fechaNacimiento;
  final int rolId;
  final bool correoVerificado;
  final bool activo;

  const Usuario({
    required this.id,
    required this.nombre,
    required this.apellido,
    required this.correo,
    this.celular,
    this.ciudad,
    this.nivelJuego,
    this.fechaNacimiento,
    this.rolId = 1,
    this.correoVerificado = false,
    this.activo = true,
  });

  factory Usuario.fromJson(Map<String, dynamic> j) => Usuario(
        id: (j['id'] ?? '') as Object,
        nombre: toStr(j['nombre']),
        apellido: toStr(j['apellido']),
        correo: toStr(j['correo']),
        celular: toStrN(j['numero_celular']),
        ciudad: toStrN(j['ciudad']),
        nivelJuego: toStrN(j['nivel_juego']),
        fechaNacimiento: toFecha(j['fecha_nacimiento']),
        rolId: toInt(j['rol_id'], 1),
        correoVerificado: toBool(j['correo_verificado']),
        activo: toBool(j['activo'], true),
      );

  RolApp get rol => RolApp.deId(rolId);
  String get nombreCompleto => '$nombre $apellido'.trim();
  String get iniciales => inicialesDe(nombre, apellido);
}

/// Perfil con foto (tabla `perfil_jugador`). Para quien no es jugador solo sirve de foto de perfil.
class PerfilJugador {
  final String? posicion;
  final String? pais;
  final String? tipoJugador;
  final String? avatarUrl;
  final String? distincion;
  final bool verificado;

  const PerfilJugador({this.posicion, this.pais, this.tipoJugador, this.avatarUrl, this.distincion, this.verificado = false});

  factory PerfilJugador.fromJson(Map<String, dynamic> j) => PerfilJugador(
        posicion: toStrN(j['posicion']),
        pais: toStrN(j['pais']),
        tipoJugador: toStrN(j['tipo_jugador']),
        avatarUrl: toStrN(j['avatar_url']),
        distincion: toStrN(j['distincion']),
        verificado: toBool(j['verificado']),
      );
}
