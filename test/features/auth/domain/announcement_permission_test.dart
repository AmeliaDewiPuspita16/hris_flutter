import 'package:flutter_test/flutter_test.dart';
import 'package:hris_mobile/features/auth/domain/auth_user.dart';

import '../../../fixtures/login_response.dart';

void main() {
  AuthUser userWithRoles(List<String> roles) {
    return AuthUser.fromJson({
      'id': 1,
      'name': 'Uji Coba',
      'email': 'uji@biie.co.id',
      'roles': [for (final role in roles) {'name': role}],
    });
  }

  group('canPublishAnnouncement', () {
    test('mengizinkan role hrga', () {
      expect(userWithRoles(['hrga']).canPublishAnnouncement, isTrue);
    });

    test('mengizinkan role admin', () {
      expect(userWithRoles(['admin']).canPublishAnnouncement, isTrue);
    });

    test('mengizinkan saat salah satu dari banyak role memenuhi', () {
      expect(
        userWithRoles(['gmo', 'it media', 'admin']).canPublishAnnouncement,
        isTrue,
      );
    });

    test('tidak membedakan huruf besar-kecil', () {
      expect(userWithRoles(['HRGA']).canPublishAnnouncement, isTrue);
    });

    test('menolak pengguna tanpa role sama sekali', () {
      expect(userWithRoles([]).canPublishAnnouncement, isFalse);
    });

    test('menolak role lain yang tidak berizin', () {
      final user = userWithRoles([
        'gmo',
        'est building',
        'daily-worker',
        'epro-requestor',
      ]);

      expect(user.canPublishAnnouncement, isFalse);
    });

    test('menolak akun contoh dari dokumentasi login', () {
      // Akun ini punya 8 role, tapi tidak satu pun hrga atau admin.
      expect(
        AuthUser.fromJson(loginResponseUser()).canPublishAnnouncement,
        isFalse,
      );
    });
  });
}
