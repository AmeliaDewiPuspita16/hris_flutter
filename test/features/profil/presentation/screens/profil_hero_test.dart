import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hris_mobile/features/auth/domain/auth_user.dart';
import 'package:hris_mobile/features/auth/presentation/bloc/auth/auth_bloc.dart';
import 'package:hris_mobile/features/profil/presentation/screens/profil_screen.dart';
import 'package:hris_mobile/features/shared/domain/role.dart';

import '../../../../fixtures/login_response.dart';
import '../../../../support/auth_harness.dart';

void main() {
  Future<void> pumpProfil(WidgetTester tester, {AuthUser? user}) {
    final authBloc = AuthBloc(repository: AuthHarness().repository);
    return tester.pumpWidget(
      MaterialApp(
        home: BlocProvider.value(
          value: authBloc,
          child: Scaffold(
            body: ProfilScreen(role: Role.hrPublisher, user: user),
          ),
        ),
      ),
    );
  }

  testWidgets('menampilkan nama, inisial, section, dan NIK pengguna',
      (tester) async {
    await pumpProfil(tester, user: AuthUser.fromJson(loginResponseUser()));

    expect(find.text('Ari Putra'), findsOneWidget);
    expect(find.text('AP'), findsOneWidget);
    expect(find.text('IT Solution'), findsOneWidget);
    expect(find.text('NIP: 0774'), findsOneWidget);
  });

  testWidgets('tidak lagi menampilkan data demo saat pengguna tersedia',
      (tester) async {
    await pumpProfil(tester, user: AuthUser.fromJson(loginResponseUser()));

    expect(find.text('Nanda Pratiwi'), findsNothing);
    expect(find.text('NIP: 0000'), findsNothing);
  });

  testWidgets('kembali ke data demo saat belum ada pengguna', (tester) async {
    await pumpProfil(tester);

    expect(find.text('Nanda Pratiwi'), findsOneWidget);
  });

  testWidgets('memakai data demo untuk field yang tidak dikirim server',
      (tester) async {
    await pumpProfil(
      tester,
      user: AuthUser.fromJson({
        'id': 1,
        'name': 'Budi Santoso',
        'email': 'budi@biie.co.id',
      }),
    );

    expect(find.text('Budi Santoso'), findsOneWidget);
    expect(find.text('HR Publisher'), findsOneWidget);
    expect(find.text('NIP: 0000'), findsOneWidget);
  });
}
