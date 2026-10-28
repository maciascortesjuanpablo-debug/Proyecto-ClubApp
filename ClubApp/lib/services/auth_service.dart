import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

class AuthService {
  // El token se guarda cifrado (Keystore en Android, Keychain en iOS)
  static const _storage = FlutterSecureStorage();

  static final _google = GoogleSignIn(
    scopes: const ['email', 'profile'],
    serverClientId: ApiConfig.googleServerClientId.isEmpty ? null : ApiConfig.googleServerClientId,
  );

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
            Uri.parse('${ApiConfig.baseUrl}$ruta'),
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

  /// Paso 1. Con la contraseña correcta el backend NO da sesión: devuelve {requiere2fa, tokenDesafio, correo}
  /// y manda un código al correo. La sesión se abre en verificarDosPasos.
  static Future<Map<String, dynamic>> iniciarSesion({required String correo, required String password}) async {
    final r = await _post('/auth/login', {'correo': correo, 'password': password}, errorPorDefecto: 'Correo o contraseña incorrectos');
    return r['exito'] == true && r['requiere2fa'] != true ? await _abrirSesion(r) : r; // sin segundo paso (DOS_PASOS=false) entra directo
  }

  /// Paso 2: valida el código del correo y abre la sesión
  static Future<Map<String, dynamic>> verificarDosPasos({required String tokenDesafio, required String codigo}) async {
    final r = await _post('/auth/verificar-2fa', {'tokenDesafio': tokenDesafio, 'codigo': codigo}, errorPorDefecto: 'Código incorrecto o expirado');
    return r['exito'] == true ? await _abrirSesion(r) : r;
  }

  static Future<Map<String, dynamic>> reenviarDosPasos({required String tokenDesafio}) =>
      _post('/auth/reenviar-2fa', {'tokenDesafio': tokenDesafio}, errorPorDefecto: 'No se pudo reenviar el código');

  /// Abre el selector de cuentas de Google y entra con el token de identidad (el backend lo valida con Google).
  /// Devuelve {exito, nuevo, cancelado, mensaje}. `nuevo` = la cuenta se acaba de crear.
  static Future<Map<String, dynamic>> iniciarSesionConGoogle() async {
    if (ApiConfig.googleServerClientId.isEmpty) {
      return {'exito': false, 'mensaje': 'Falta configurar GOOGLE_SERVER_CLIENT_ID para entrar con Google'};
    }
    try {
      await _google.signOut(); // así siempre muestra el selector de cuentas
      final cuenta = await _google.signIn();
      if (cuenta == null) return {'exito': false, 'cancelado': true}; // cerró el selector


      final idToken = (await cuenta.authentication).idToken;
      if (idToken == null) return {'exito': false, 'mensaje': 'Google no entregó el token de identidad. Revisa el cliente OAuth en Google Cloud'};

      final r = await _post('/auth/google', {'idToken': idToken}, errorPorDefecto: 'No se pudo iniciar sesión con Google');
      return r['exito'] == true ? await _abrirSesion(r) : r;
    } catch (e) {
      // ApiException 10 = SHA-1 o nombre de paquete no coinciden; 12500 = falta configurar la pantalla de consentimiento
      debugPrint('Google Sign-In: $e');
      return {'exito': false, 'mensaje': 'No se pudo conectar con Google. Revisa la configuración (SHA-1, nombre de paquete y client ID)'};
    }
  }

  /// Quien entró con Google nace como "Usuario" y elige su rol una sola vez. El backend devuelve un token nuevo con ese rol.
  static Future<Map<String, dynamic>> elegirRol(int rolId) async {
    final r = await _post('/usuarios/elegir-rol', {'rol_id': rolId}, conSesion: true, errorPorDefecto: 'No se pudo guardar el rol');
    return r['exito'] == true ? await _abrirSesion(r) : r;
  }

  static Future<Map<String, dynamic>> _abrirSesion(Map<String, dynamic> r) async {
    _token = r['token'] as String;
    _usuario = r['usuario'] as Map<String, dynamic>;
    await _storage.write(key: 'token', value: _token);
    await _storage.write(key: 'usuario', value: jsonEncode(_usuario));
    return r;
  }

  /// Actualiza en memoria y en el almacenamiento seguro los datos del usuario (p. ej. tras editar el perfil)
  static Future<void> actualizarUsuarioLocal(Map<String, dynamic> cambios) async {
    if (_usuario == null) return;
    _usuario = {..._usuario!, ...cambios};
    await _storage.write(key: 'usuario', value: jsonEncode(_usuario));
  }


  static Future<void> logout() async {
    _token = null;
    _usuario = null;
    try {
      await _storage.delete(key: 'token');
      await _storage.delete(key: 'usuario');
      await _google.signOut(); // cierra también la cuenta de Google para que la próxima vez pida elegir
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