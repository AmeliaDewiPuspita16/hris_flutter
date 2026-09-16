import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hris_mobile/features/auth/domain/auth_user.dart';
import 'package:hris_mobile/features/profil/domain/employee_profile.dart';
import 'package:hris_mobile/features/profil/presentation/screens/data_diri_screen.dart';
import 'package:hris_mobile/features/shared/domain/role.dart';

import '../../../../fixtures/login_response.dart';

void main() {
  final demo = EmployeeProfile.of(Role.hrPublisher);

  Future<void> pumpDataDiri(WidgetTester tester, {AuthUser? user}) {
    return tester.pumpWidget(
      MaterialApp(home: DataDiriScreen(profile: demo, user: user)),
    );
  }

  group('dengan sesi pengguna', () {
    testWidgets('menampilkan No. HP dan Email dari sesi', (tester) async {
      await pumpDataDiri(tester, user: AuthUser.fromJson(loginResponseUser()));

      expect(find.text('082269859515'), findsOneWidget);
      expect(find.text('ariputra@biie.co.id'), findsOneWidget);
    });

    testWidgets('menampilkan NIP dari nik', (tester) async {
      await pumpDataDiri(tester, user: AuthUser.fromJson(loginResponseUser()));

      expect(find.text('0774'), findsOneWidget);
    });

    testWidgets('menampilkan tanggal lahir dalam format tampilan',
        (tester) async {
      await pumpDataDiri(tester, user: AuthUser.fromJson(loginResponseUser()));

      expect(find.text('21-11-1991'), findsOneWidget);
      expect(find.text('1991-11-21'), findsNothing);
    });

    testWidgets('tidak lagi menampilkan kontak demo', (tester) async {
      await pumpDataDiri(tester, user: AuthUser.fromJson(loginResponseUser()));

      expect(find.text(demo.phone), findsNothing);
      expect(find.text(demo.email), findsNothing);
    });

    testWidgets('membiarkan field yang tidak ada di API tetap dari demo',
        (tester) async {
      await pumpDataDiri(tester, user: AuthUser.fromJson(loginResponseUser()));

      expect(find.text(demo.employeeCategory), findsOneWidget);
      expect(find.text(demo.birthPlace), findsOneWidget);
      expect(find.text(demo.religion), findsOneWidget);
      expect(find.text(demo.maritalStatus), findsOneWidget);
      expect(find.text(demo.degree), findsOneWidget);
    });

    testWidgets('jatuh ke demo untuk field yang tidak dikirim server',
        (tester) async {
      await pumpDataDiri(
        tester,
        user: AuthUser.fromJson({
          'id': 1,
          'name': 'Budi Santoso',
          'email': 'budi@biie.co.id',
        }),
      );

      expect(find.text('budi@biie.co.id'), findsOneWidget);
      expect(find.text(demo.phone), findsOneWidget);
      expect(find.text(demo.nip), findsOneWidget);
      expect(find.text(demo.birthDate), findsOneWidget);
    });

    testWidgets('memakai tanggal demo saat date_of_birth tidak bisa diurai',
        (tester) async {
      await pumpDataDiri(
        tester,
        user: AuthUser.fromJson({
          'id': 1,
          'name': 'Budi',
          'email': 'budi@biie.co.id',
          'date_of_birth': '0000-00-00',
        }),
      );

      expect(find.text(demo.birthDate), findsOneWidget);
    });
  });

  testWidgets('memakai seluruh data demo saat belum ada sesi', (tester) async {
    await pumpDataDiri(tester);

    expect(find.text(demo.phone), findsOneWidget);
    expect(find.text(demo.email), findsOneWidget);
    expect(find.text(demo.nip), findsOneWidget);
    expect(find.text(demo.birthDate), findsOneWidget);
  });
}
