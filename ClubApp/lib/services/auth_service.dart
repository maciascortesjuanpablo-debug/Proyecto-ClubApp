import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import '../core/app_constants.dart';

class AuthService {
  // El token se guarda cifrado (Keystore en Android, Keychain en iOS)
  static const _storage = FlutterSecureStorage();

  static String? _token;
  static Map<String, dynamic>? _usuario;

  static bool get isLoggedIn => _token != null;
  static bool get isGuest => !isLoggedIn;
  static String? get token => _token;
  static Map<String, dynamic>? get usuario => _usuario;

  /// Restaura la sesión guardada (si existe y el token no ha vencido)
  static Future<void> cargarSesion() async {
    try {
      final token = await _storage.read(key: 'token');
      final usuario = await _storage.read(key: 'usuario');
      if (token == null || usuario == null || _vencido(token)) {
        await logout();
        return;
      }
      _token = token;
      _usuario = jsonDecode(usuario) as Map<String, dynamic>;
    } catch (_) {
      await logout();
    }
  }

  /// Lee la fecha de expiración (exp) del JWT sin validar la firma: eso lo hace el servidor
  static bool _vencido(String jwt) {
    try {
      final payload = jsonDecode(utf8.decode(base64Url.decode(base64Url.normalize(jwt.split('.')[1]))));
      return DateTime.now().millisecondsSinceEpoch ~/ 1000 >= (payload['exp'] as int);
    } catch (_) {
      return true;
    }
  }

  /// POST al backend. Devuelve {exito, mensaje, ...datos de la respuesta}
  static Future<Map<String, dynamic>> _post(
    String ruta,
    Map<String, dynamic> cuerpo, {
    int ok = 200,
    String errorPorDefecto = 'Ocurrió un error',
    bool conSesion = false,
  }) async {
    try {
      final r = await http
          .post(
            Uri.parse('${AppConfig.apiUrl}$ruta'),
            headers: {'Content-Type': 'application/json', if (conSesion && _token != null) 'Authorization': 'Bearer $_token'},
            body: jsonEncode(cuerpo),
          )
          .timeout(const Duration(seconds: 15));
      final data = jsonDecode(r.body) as Map<String, dynamic>;
      return r.statusCode == ok ? {...data, 'exito': true} : {'exito': false, 'mensaje': data['mensaje'] ?? errorPorDefecto};
    } catch (_) {
      return {'exito': false, 'mensaje': 'No se pudo conectar al servidor'};
    }
  }

  static Future<Map<String, dynamic>> registrar({
    required String nombre,
    required String apellido,
    required String correo,
    required String numeroCelular,
    required String fechaNacimiento, // formato yyyy-MM-dd
    required String ciudad,
    required String password,
    required int rolId,
    required String nivelJuego,
  }) =>
      _post(
        '/auth/registro',
        {
          'nombre': nombre,
          'apellido': apellido,
          'correo': correo,
          'numero_celular': numeroCelular,
          'fecha_nacimiento': fechaNacimiento,
          'ciudad': ciudad,
          'password': password,
          'rol_id': rolId,
          'nivel_juego': nivelJuego,
        },
        ok: 201,
        errorPorDefecto: 'Error al registrar',
      );

  static Future<Map<String, dynamic>> iniciarSesion({required String correo, required String password}) async {
    final r = await _post('/auth/login', {'correo': correo, 'password': password}, errorPorDefecto: 'Correo o contraseña incorrectos');
    if (r['exito'] == true) {
      _token = r['token'] as String;
      _usuario = r['usuario'] as Map<String, dynamic>;
      await _storage.write(key: 'token', value: _token);
      await _storage.write(key: 'usuario', value: jsonEncode(_usuario));
    }
    return r;
  }

  static Future<void> logout() async {
    _token = null;
    _usuario = null;
    try {
      await _storage.delete(key: 'token');
      await _storage.delete(key: 'usuario');
    } catch (_) {}
  }

  /// No bloquea el registro si falla: el usuario puede completar su perfil después
  static Future<void> crearPerfilJugador({required String posicion}) =>
      _post('/perfil-jugador', {'posicion': posicion}, ok: 201, conSesion: true);

  static Future<Map<String, dynamic>> enviarCodigoRecuperacion({required String correo}) =>
      _post('/recuperar-password/enviar-codigo', {'correo': correo}, errorPorDefecto: 'No se pudo enviar el código');

  static Future<Map<String, dynamic>> verificarCodigoRecuperacion({required String correo, required String codigo}) =>
      _post('/recuperar-password/verificar-codigo', {'correo': correo, 'codigo': codigo}, errorPorDefecto: 'Código incorrecto o expirado');

  static Future<Map<String, dynamic>> cambiarPasswordConToken({required String tokenTemporal, required String nuevaPassword}) =>
      _post('/recuperar-password/cambiar-password', {'tokenTemporal': tokenTemporal, 'nuevaPassword': nuevaPassword},
          errorPorDefecto: 'No se pudo cambiar la contraseña');
}
