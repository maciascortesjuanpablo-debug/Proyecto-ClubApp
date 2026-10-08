import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static bool _isLoggedIn = false;
  static String? _token;
  static Map<String, dynamic>? _usuario;

  static bool get isLoggedIn => _isLoggedIn;
  static bool get isGuest => !_isLoggedIn;
  static String? get token => _token;
  static Map<String, dynamic>? get usuario => _usuario;

  // 10.0.2.2 = localhost de tu PC visto desde el emulador de Android
  static const String baseUrl = 'http://10.0.2.2:3000/api';


  static Future<void> cargarSesion() async {
    final prefs = await SharedPreferences.getInstance();
    final tokenGuardado = prefs.getString('token');

    if (tokenGuardado != null) {
      _token = tokenGuardado;
      _isLoggedIn = true;
      _usuario = {
        'id': prefs.getString('usuario_id'),
        'nombre': prefs.getString('usuario_nombre'),
        'rol_id': prefs.getInt('rol_id'),
      };
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
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/registro'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'nombre': nombre,
          'apellido': apellido,
          'correo': correo,
          'numero_celular': numeroCelular,
          'fecha_nacimiento': fechaNacimiento,
          'ciudad': ciudad,
          'password': password,
        }),
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 201) {
        return {'exito': true, 'mensaje': data['mensaje']};
      } else {
        return {
          'exito': false,
          'mensaje': data['mensaje'] ?? 'Error al registrar',
        };
      }
    } catch (e) {
      return {'exito': false, 'mensaje': 'No se pudo conectar al servidor'};
    }
  }
  static Future<Map<String, dynamic>> iniciarSesion({
    required String correo,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'correo': correo, 'password': password}),
      );
      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        _token = data['token'];
        _isLoggedIn = true;
        _usuario = data['usuario'];
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', _token!);
        await prefs.setString('usuario_id', _usuario!['id'].toString());
        await prefs.setString('usuario_nombre', _usuario!['nombre']);
        await prefs.setInt('rol_id', _usuario!['rol_id']);
        return {'exito': true};
      } else {
        return {
          'exito': false,
          'mensaje': data['mensaje'] ?? 'Correo o contraseña incorrectos',
        };
      }
    } catch (e) {
      return {'exito': false, 'mensaje': 'No se pudo conectar al servidor'};
    }
  }
  static Future<void> logout() async {
    _isLoggedIn = false;
    _token = null;
    _usuario = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
  static Future<void> crearPerfilJugador({required String posicion}) async {
    if (_token == null || _usuario == null) return;
    try {
      await http.post(
        Uri.parse('$baseUrl/perfil-jugador'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_token',
        },
        body: jsonEncode({'usuario_id': _usuario!['id'], 'posicion': posicion}),
      );
    } catch (_) {
    }
  }
  static Future<Map<String, dynamic>> enviarCodigoRecuperacion({
    required String correo,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/recuperar-password/enviar-codigo'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'correo': correo}),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {'exito': true, 'mensaje': data['mensaje']};
      } else {
        return {
          'exito': false,
          'mensaje': data['mensaje'] ?? 'No se pudo enviar el código',
        };
      }
    } catch (e) {
      return {'exito': false, 'mensaje': 'No se pudo conectar al servidor'};
    }
  }

  static Future<Map<String, dynamic>> verificarCodigoRecuperacion({
    required String correo,
    required String codigo,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/recuperar-password/verificar-codigo'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'correo': correo, 'codigo': codigo}),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {'exito': true, 'tokenTemporal': data['tokenTemporal']};
      } else {
        return {
          'exito': false,
          'mensaje': data['mensaje'] ?? 'Código incorrecto o expirado',
        };
      }
    } catch (e) {
      return {'exito': false, 'mensaje': 'No se pudo conectar al servidor'};
    }
  }

  static Future<Map<String, dynamic>> cambiarPasswordConToken({
    required String tokenTemporal,
    required String nuevaPassword,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/recuperar-password/cambiar-password'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'tokenTemporal': tokenTemporal,
          'nuevaPassword': nuevaPassword,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {'exito': true, 'mensaje': data['mensaje']};
      } else {
        return {
          'exito': false,
          'mensaje': data['mensaje'] ?? 'No se pudo cambiar la contraseña',
        };
      }
    } catch (e) {
      return {'exito': false, 'mensaje': 'No se pudo conectar al servidor'};
    }
  }

  static void requireAuth(BuildContext context) {
    if (isGuest) {
      _showGuestAlert(context);
    }
  }

  static void _showGuestAlert(BuildContext context) {
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text(
          'Inicia Sesión',
          style: TextStyle(color: Color(0xFFFFFFFF)),
        ),
        content: const Text(
          'Necesitas una cuenta para esta acción',
          style: TextStyle(color: Color(0xFF94A3B8)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(c);
              Navigator.pushNamed(c, '/login');
            },
            child: const Text('Registrarse'),
          ),
        ],
      ),
    );
  }
}
