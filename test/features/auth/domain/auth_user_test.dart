import 'package:flutter_test/flutter_test.dart';
import 'package:hris_mobile/features/auth/domain/auth_user.dart';

import '../../../fixtures/login_response.dart';

void main() {
  group('AuthUser.fromJson', () {
    test('memetakan field dasar dari respons login sebenarnya', () {
      final user = AuthUser.fromJson(loginResponseUser());

      expect(user.id, 3);
      expect(user.name, 'Ari Putra');
      expect(user.email, 'ariputra@biie.co.id');
      expect(user.nik, '0774');
      expect(user.phone, '082269859515');
      expect(user.section, 'IT Solution');
      expect(user.departmentId, 18);
      expect(user.subDepartmentId, 0);
      expect(user.dateOfBirth, '1991-11-21');
      expect(user.gender, 'male');
      expect(user.avatar, 'avatar.png');
    });

    test('menyimpan image apa adanya karena server mengirim nama berkas', () {
      final user = AuthUser.fromJson(loginResponseUser());

      expect(user.image, 'ElAfRcrE0ZRtHsLm5PvIqGo32hIc0n3OrlmC8lsz.jpg');
    });

    test('memeras objek roles menjadi daftar nama saja', () {
      final user = AuthUser.fromJson(loginResponseUser());

      expect(user.roles, [
        'gmo',
        'est building',
        'it media',
        'daily-worker',
        'Foodcost-Admin',
        'epro-requestor',
        'epro-approver-finance',
        'est iot meter reading email report',
      ]);
    });

    test('memberi daftar roles kosong saat field roles tidak dikirim', () {
      final user = AuthUser.fromJson({
        'id': 3,
        'name': 'Ari Putra',
        'email': 'ariputra@biie.co.id',
      });

      expect(user.roles, isEmpty);
    });

    test('membiarkan field opsional null saat server tidak mengirimnya', () {
      final user = AuthUser.fromJson({
        'id': 7,
        'name': 'Karyawan Baru',
        'email': 'baru@biie.co.id',
      });

      expect(user.nik, isNull);
      expect(user.phone, isNull);
      expect(user.section, isNull);
      expect(user.departmentId, isNull);
      expect(user.dateOfBirth, isNull);
      expect(user.image, isNull);
    });

    test('tetap terbaca saat id dikirim server sebagai teks', () {
      final user = AuthUser.fromJson({
        'id': '3',
        'name': 'Ari Putra',
        'email': 'ariputra@biie.co.id',
        'id_department': '18',
      });

      expect(user.id, 3);
      expect(user.departmentId, 18);
    });

    test('mengabaikan entri role yang tidak punya nama', () {
      final user = AuthUser.fromJson({
        'id': 3,
        'name': 'Ari Putra',
        'email': 'ariputra@biie.co.id',
        'roles': [
          {'id': 8, 'name': 'gmo'},
          {'id': 9},
        ],
      });

      expect(user.roles, ['gmo']);
    });
  });

  group('AuthUser.toJson', () {
    test('memakai nama field yang sama dengan server', () {
      final user = AuthUser.fromJson(loginResponseUser());

      final json = user.toJson();

      expect(json['id'], 3);
      expect(json['no_hp'], '082269859515');
      expect(json['id_department'], 18);
      expect(json['date_of_birth'], '1991-11-21');
    });

    test('menulis roles dalam bentuk objek bernama seperti respons server',
        () {
      final user = AuthUser.fromJson(loginResponseUser());

      final roles = user.toJson()['roles'] as List;

      expect(roles.first, {'name': 'gmo'});
      expect(roles, hasLength(8));
    });
  });

  group('AuthUser.hasRole', () {
    test('mengenali role yang dimiliki tanpa membedakan huruf besar-kecil',
        () {
      final user = AuthUser.fromJson(loginResponseUser());

      expect(user.hasRole('it media'), isTrue);
      expect(user.hasRole('Foodcost-Admin'), isTrue);
      expect(user.hasRole('foodcost-admin'), isTrue);
    });

    test('menolak role yang tidak dimiliki', () {
      final user = AuthUser.fromJson(loginResponseUser());

      expect(user.hasRole('super-admin'), isFalse);
    });
  });
}
