import 'package:flutter/material.dart';

class AuthService {
  static bool _isLoggedIn = false;

  static bool get isLoggedIn => _isLoggedIn;
  static bool get isGuest => !_isLoggedIn;

  static void login() => _isLoggedIn = true;
  static void logout() => _isLoggedIn = false;

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
        title: const Text('Inicia Sesión', style: TextStyle(color: Color(0xFFFFFFFF))),
        content: const Text('Necesitas una cuenta para esta acción',
          style: TextStyle(color: Color(0xFF94A3B8))),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c), child: const Text('Cancelar')),
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