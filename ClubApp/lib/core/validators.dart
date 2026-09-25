// lib/core/validators.dart

class AppValidators {
  // Email validation
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'El correo es requerido';
    }
    if (!RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$')
        .hasMatch(value)) {
      return 'Correo inválido';
    }
    return null;
  }

  // Password validation
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'La contraseña es requerida';
    }
    if (value.length < 8) {
      return 'Mínimo 8 caracteres';
    }
    return null;
  }

  // Confirm password validation
  static String? validateConfirmPassword(String? value, String password) {
    if (value == null || value.isEmpty) {
      return 'Confirma tu contraseña';
    }
    if (value != password) {
      return 'Las contraseñas no coinciden';
    }
    return null;
  }

  // Name validation
  static String? validateName(String? value) {
    if (value == null || value.isEmpty) {
      return 'El nombre es requerido';
    }
    return null;
  }

  // Last names validation
  static String? validateLastNames(String? value) {
    if (value == null || value.isEmpty) {
      return 'Los apellidos son requeridos';
    }
    return null;
  }

  // Phone validation
  static String? validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return 'El celular es requerido';
    }
    return null;
  }

  // Date validation
  static String? validateDate(String? value) {
    if (value == null || value.isEmpty) {
      return 'La fecha es requerida';
    }
    return null;
  }

  // Position validation
  static String? validatePosition(String? value) {
    if (value == null || value.isEmpty) {
      return 'La posición es requerida';
    }
    return null;
  }

  // City validation
  static String? validateCity(String? value) {
    if (value == null || value.isEmpty) {
      return 'La ciudad es requerida';
    }
    return null;
  }

  // Generic not empty validation
  static String? validateNotEmpty(String? value, String fieldName) {
    if (value == null || value.isEmpty) {
      return '$fieldName es requerido';
    }
    return null;
  }

  // Password strength check
  static PasswordStrength checkPasswordStrength(String password) {
    return PasswordStrength(
      hasMinChars: password.length >= 8,
      hasUpperCase: password.contains(RegExp(r'[A-Z]')),
      hasNumber: password.contains(RegExp(r'[0-9]')),
      hasSpecialChar: password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]')),
    );
  }
}

class PasswordStrength {
  final bool hasMinChars;
  final bool hasUpperCase;
  final bool hasNumber;
  final bool hasSpecialChar;

  PasswordStrength({
    required this.hasMinChars,
    required this.hasUpperCase,
    required this.hasNumber,
    required this.hasSpecialChar,
  });

  bool get isStrong =>
      hasMinChars && hasUpperCase && hasNumber && hasSpecialChar;
}