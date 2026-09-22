import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hris_mobile/features/auth/domain/auth_user.dart';
import 'package:hris_mobile/features/home/presentation/widgets/home_top_header.dart';
import 'package:hris_mobile/features/shared/domain/role.dart';

import '../../../../fixtures/login_response.dart';

void main() {
  Future<void> pumpHeader(WidgetTester tester, {AuthUser? user}) {
    return tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: HomeTopHeader(role: Role.hrPublisher, user: user),
        ),
      ),
    );
  }

  testWidgets('menyapa dengan nama depan pengguna yang masuk', (tester) async {
    await pumpHeader(tester, user: AuthUser.fromJson(loginResponseUser()));

    expect(find.text('Hi, Ari'), findsOneWidget);
    expect(find.text('Hi, Nanda'), findsNothing);
  });

  testWidgets('menampilkan foto profil saat user punya image', (tester) async {
    final user = AuthUser.fromJson(loginResponseUser());
    await pumpHeader(tester, user: user);

    final image = tester.widget<Image>(find.byType(Image));
    expect((image.image as NetworkImage).url, user.photoUrl);
  });

  testWidgets('menampilkan inisial saat user belum punya foto', (tester) async {
    await pumpHeader(
      tester,
      user: AuthUser.fromJson({
        'id': 1,
        'name': 'Ari Putra',
        'email': 'ariputra@biie.co.id',
      }),
    );

    expect(find.text('AP'), findsOneWidget);
    expect(find.byType(Image), findsNothing);
  });

  testWidgets('menampilkan section sebagai baris kedua', (tester) async {
    await pumpHeader(tester, user: AuthUser.fromJson(loginResponseUser()));

    expect(find.text('IT Solution'), findsOneWidget);
    expect(find.text('HR Publisher'), findsNothing);
  });

  testWidgets('kembali ke data demo saat belum ada pengguna', (tester) async {
    await pumpHeader(tester);

    expect(find.text('Hi, Nanda'), findsOneWidget);
    expect(find.text('NP'), findsOneWidget);
    expect(find.text('HR Publisher'), findsOneWidget);
  });

  testWidgets('memakai jabatan demo saat section tidak dikirim server',
      (tester) async {
    await pumpHeader(
      tester,
      user: AuthUser.fromJson({
        'id': 1,
        'name': 'Budi Santoso',
        'email': 'budi@biie.co.id',
      }),
    );

    expect(find.text('Hi, Budi'), findsOneWidget);
    expect(find.text('HR Publisher'), findsOneWidget);
  });
}
