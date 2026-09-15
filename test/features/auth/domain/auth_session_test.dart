import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:hris_mobile/features/auth/domain/auth_session.dart';

import '../../../fixtures/login_response.dart';

void main() {
  group('AuthSession.fromJson', () {
    test('mengambil token, tipe token, dan pengguna dari objek data', () {
      final session = AuthSession.fromJson(loginResponseData());

      expect(session.token, '9999|TOKENPALSUUNTUKPENGUJIANSAJA0000000000');
      expect(session.tokenType, 'Bearer');
      expect(session.user.name, 'Ari Putra');
    });

    test('menganggap tipe token Bearer saat server tidak mengirimnya', () {
      final data = loginResponseData()..remove('token_type');

      final session = AuthSession.fromJson(data);

      expect(session.tokenType, 'Bearer');
    });

    test('menolak data yang tidak memuat access_token', () {
      final data = loginResponseData()..remove('access_token');

      expect(() => AuthSession.fromJson(data), throwsA(isA<FormatException>()));
    });

    test('menolak data yang tidak memuat objek user', () {
      final data = loginResponseData()..remove('user');

      expect(() => AuthSession.fromJson(data), throwsA(isA<FormatException>()));
    });
  });

  group('AuthSession.toJson', () {
    test('menghasilkan bentuk yang bisa dibaca ulang oleh fromJson', () {
      final original = AuthSession.fromJson(loginResponseData());

      final restored = AuthSession.fromJson(original.toJson());

      expect(restored.token, original.token);
      expect(restored.tokenType, original.tokenType);
      expect(restored.user.id, original.user.id);
      expect(restored.user.name, original.user.name);
      expect(restored.user.email, original.user.email);
      expect(restored.user.nik, original.user.nik);
      expect(restored.user.section, original.user.section);
      expect(restored.user.departmentId, original.user.departmentId);
      expect(restored.user.image, original.user.image);
      expect(restored.user.roles, original.user.roles);
    });

    test('bertahan melewati encode dan decode JSON', () {
      final original = AuthSession.fromJson(loginResponseData());

      final restored = AuthSession.fromJson(
        jsonDecode(jsonEncode(original.toJson())) as Map<String, dynamic>,
      );

      expect(restored.token, original.token);
      expect(restored.user.roles, original.user.roles);
    });
  });
}
