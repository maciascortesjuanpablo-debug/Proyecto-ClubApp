class AppValidators {
  static const String _msgPassword = 'Mínimo 8 caracteres, una mayúscula, un número y un carácter especial';

  /// Texto obligatorio (ignora espacios)
  static String? validateRequired(String? v, String mensaje) => (v == null || v.trim().isEmpty) ? mensaje : null;

  static String? validateEmail(String? v) =>
      validateRequired(v, 'El correo es requerido') ??
      (RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]{2,}$').hasMatch(v!.trim()) ? null : 'Correo inválido');

  /// Contraseña NUEVA (registro / recuperación): misma política que el backend
  static String? validatePassword(String? v) =>
      validateRequired(v, 'La contraseña es requerida') ?? (checkPasswordStrength(v!).isStrong ? null : _msgPassword);

  static String? validateConfirmPassword(String? v, String password) =>
      validateRequired(v, 'Confirma tu contraseña') ?? (v == password ? null : 'Las contraseñas no coinciden');

  static String? validateName(String? v) => validateRequired(v, 'El nombre es requerido');
  static String? validateLastNames(String? v) => validateRequired(v, 'Los apellidos son requeridos');
  static String? validateDate(String? v) => validateRequired(v, 'La fecha es requerida');

  /// Celular colombiano: 10 dígitos que empiezan por 3 (acepta prefijo +57)
  static String? validatePhone(String? v) =>
      validateRequired(v, 'El celular es requerido') ??
      (RegExp(r'^(\+57)?3\d{9}$').hasMatch(v!.replaceAll(RegExp(r'[\s-]'), '')) ? null : 'Celular inválido (ej: 3001234567)');

  static PasswordStrength checkPasswordStrength(String password) => PasswordStrength(
        hasMinChars: password.length >= 8,
        hasUpperCase: password.contains(RegExp(r'[A-Z]')),
        hasNumber: password.contains(RegExp(r'[0-9]')),
        hasSpecialChar: password.contains(RegExp(r'[^A-Za-z0-9]')),
      );
}

class PasswordStrength {
  final bool hasMinChars;
  final bool hasUpperCase;
  final bool hasNumber;
  final bool hasSpecialChar;

  const PasswordStrength({
    required this.hasMinChars,
    required this.hasUpperCase,
    required this.hasNumber,
    required this.hasSpecialChar,
  });

  /// Requisitos cumplidos (0 a 4)
  int get puntaje => [hasMinChars, hasUpperCase, hasNumber, hasSpecialChar].where((c) => c).length;

  bool get isStrong => puntaje == 4;
}
