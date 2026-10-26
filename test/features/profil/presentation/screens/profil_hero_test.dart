import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hris_mobile/features/auth/domain/auth_user.dart';
import 'package:hris_mobile/features/auth/presentation/bloc/auth/auth_bloc.dart';
import 'package:hris_mobile/features/profil/data/profil_repository.dart';
import 'package:hris_mobile/features/profil/presentation/screens/profil_screen.dart';
import 'package:hris_mobile/features/profil/presentation/widgets/profile_avatar.dart';
import 'package:hris_mobile/features/shared/domain/role.dart';

import '../../../../fixtures/login_response.dart';
import '../../../../support/auth_harness.dart';

void main() {
  // Header juga memuat gambar cover, jadi pencarian Image dibatasi ke avatar.
  final avatarImage = find.descendant(
    of: find.byType(ProfileAvatar),
    matching: find.byType(Image),
  );

  Future<void> pumpProfil(WidgetTester tester, {AuthUser? user}) {
    final harness = AuthHarness();
    final authBloc = AuthBloc(repository: harness.repository);
    return tester.pumpWidget(
      MaterialApp(
        home: BlocProvider.value(
          value: authBloc,
          child: Scaffold(
            body: ProfilScreen(
              role: Role.hrPublisher,
              user: user,
              repository: ProfilRepository(apiClient: harness.apiClient),
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('menampilkan nama, section, dan NIK pengguna', (tester) async {
    await pumpProfil(tester, user: AuthUser.fromJson(loginResponseUser()));

    expect(find.text('Ari Putra'), findsOneWidget);
    expect(find.text('IT Solution'), findsOneWidget);
    expect(find.text('NIP: 0774'), findsOneWidget);
  });

  testWidgets('menampilkan foto profil saat user punya image', (tester) async {
    final user = AuthUser.fromJson(loginResponseUser());
    await pumpProfil(tester, user: user);

    final image = tester.widget<Image>(avatarImage);
    expect((image.image as NetworkImage).url, user.photoUrl);
  });

  testWidgets('menampilkan inisial saat user belum punya foto', (tester) async {
    await pumpProfil(
      tester,
      user: AuthUser.fromJson({
        'id': 1,
        'name': 'Ari Putra',
        'email': 'ariputra@biie.co.id',
      }),
    );

    expect(find.text('AP'), findsOneWidget);
    expect(avatarImage, findsNothing);
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

  testWidgets('menampilkan data login kecuali role', (tester) async {
    await pumpProfil(tester, user: AuthUser.fromJson(loginResponseUser()));

    expect(find.text('ariputra@biie.co.id'), findsOneWidget);
    expect(find.text('082269859515'), findsOneWidget);
    expect(find.text('Male'), findsOneWidget);
    expect(find.text('gmo'), findsNothing);
  });

  testWidgets('menu HRIS yang datanya masih demo disembunyikan',
      (tester) async {
    await pumpProfil(tester, user: AuthUser.fromJson(loginResponseUser()));

    expect(find.text('Update Password'), findsOneWidget);
    for (final hidden in [
      'Personal Data',
      'Employment Contract',
      'Bank Account',
      'Address',
      'Dependents',
    ]) {
      expect(find.text(hidden), findsNothing);
    }
  });
}
