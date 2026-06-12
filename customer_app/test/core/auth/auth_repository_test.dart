import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:customer_app/core/auth/auth_models.dart';
import 'package:customer_app/core/auth/auth_repository.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  group('AuthRepository Model Tests', () {
    test('AuthUser fromJson maps fields correctly', () {
      final json = {
        'id': 'user-123',
        'name': 'John Doe',
        'email': 'john@example.com',
        'phone': '9876543210',
        'role': 'user',
        'token': 'jwt-token-string'
      };

      final user = AuthUser.fromJson(json);
      expect(user.id, 'user-123');
      expect(user.name, 'John Doe');
      expect(user.email, 'john@example.com');
      expect(user.phone, '9876543210');
      expect(user.role, 'user');
      expect(user.token, 'jwt-token-string');
    });

    test('LoginPayload toJson maps correct fields', () {
      const payload = LoginPayload(
        email: '  JOHN@example.com  ',
        password: 'password123',
        rememberMe: true,
      );

      final json = payload.toJson();
      expect(json['email'], 'john@example.com');
      expect(json['password'], 'password123');
      expect(json['rememberMe'], true);
    });
  });
}
