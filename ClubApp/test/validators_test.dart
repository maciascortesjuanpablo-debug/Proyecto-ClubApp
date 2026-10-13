import 'package:flutter_test/flutter_test.dart';
import 'package:clubapp/core/validators.dart';

void main() {
  group('AppValidators', () {
    test('correo', () {
      expect(AppValidators.validateEmail('tu@email.com'), isNull);
      expect(AppValidators.validateEmail('tu@email'), isNotNull);
      expect(AppValidators.validateEmail('  '), isNotNull);
    });

    test('contraseña nueva exige 8 caracteres, mayúscula, número y especial', () {
      expect(AppValidators.validatePassword('Abcdef1!'), isNull);
      expect(AppValidators.validatePassword('abcdef1!'), isNotNull);
      expect(AppValidators.validatePassword('Abcdefg!'), isNotNull);
      expect(AppValidators.validatePassword('Abc1!'), isNotNull);
      expect(AppValidators.checkPasswordStrength('Abcdef1!').puntaje, 4);
    });

    test('celular colombiano', () {
      expect(AppValidators.validatePhone('3001234567'), isNull);
      expect(AppValidators.validatePhone('+57 300 123 4567'), isNull);
      expect(AppValidators.validatePhone('30012345'), isNotNull);
    });

    test('confirmación de contraseña', () {
      expect(AppValidators.validateConfirmPassword('a', 'a'), isNull);
      expect(AppValidators.validateConfirmPassword('a', 'b'), isNotNull);
    });
  });
}
