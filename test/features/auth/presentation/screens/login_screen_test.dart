import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:hris_mobile/core/widgets/app_button.dart';
import 'package:hris_mobile/features/auth/data/auth_repository.dart';
import 'package:hris_mobile/features/auth/presentation/bloc/auth/auth_bloc.dart';
import 'package:hris_mobile/features/auth/presentation/bloc/auth/auth_state.dart';
import 'package:hris_mobile/features/auth/presentation/screens/login_screen.dart';

import '../../../../support/auth_harness.dart';

void main() {
  late AuthHarness harness;
  late AuthBloc authBloc;

  Future<void> pumpLoginScreen(
    WidgetTester tester, {
    Future<http.Response> Function(http.Request request)? handler,
  }) async {
    harness = AuthHarness(handler: handler);
    authBloc = AuthBloc(repository: harness.repository);

    await tester.pumpWidget(
      MaterialApp(
        home: RepositoryProvider<AuthRepository>.value(
          value: harness.repository,
          child: BlocProvider.value(
            value: authBloc,
            child: const LoginScreen(),
          ),
        ),
      ),
    );
  }

  Future<void> fillValidCredentials(WidgetTester tester) async {
    await tester.enterText(
      find.byType(TextField).first,
      'ariputra@biie.co.id',
    );
    await tester.enterText(find.byType(TextField).last, 'rahasia');
  }

  Future<void> tapSignIn(WidgetTester tester) async {
    await tester.tap(find.widgetWithText(AppButton, 'Sign in'));
  }

  testWidgets('tidak memanggil API saat input belum lolos validasi lokal',
      (tester) async {
    var requestCount = 0;
    await pumpLoginScreen(
      tester,
      handler: (_) async {
        requestCount++;
        return AuthHarness.successfulLoginResponse();
      },
    );

    await tapSignIn(tester);
    await tester.pump();

    expect(requestCount, 0);
    expect(find.text('Email wajib diisi'), findsOneWidget);
  });

  testWidgets('menampilkan indikator pada tombol selagi menunggu server',
      (tester) async {
    final releaseResponse = Completer<void>();
    await pumpLoginScreen(
      tester,
      handler: (_) async {
        await releaseResponse.future;
        return AuthHarness.successfulLoginResponse();
      },
    );

    await fillValidCredentials(tester);
    await tapSignIn(tester);
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Sign in'), findsNothing);

    releaseResponse.complete();
    await tester.pumpAndSettle();
  });

  testWidgets('menampilkan pesan galat dari server saat kredensial salah',
      (tester) async {
    await pumpLoginScreen(
      tester,
      handler: (_) async => AuthHarness.unauthorizedResponse(),
    );

    await fillValidCredentials(tester);
    await tapSignIn(tester);
    await tester.pumpAndSettle();

    expect(find.text('Email atau kata sandi salah.'), findsOneWidget);
    expect(find.text('Sign in'), findsOneWidget);
  });

  testWidgets('menampilkan pesan jaringan saat koneksi gagal', (tester) async {
    await pumpLoginScreen(
      tester,
      handler: (_) async => throw http.ClientException('Connection closed'),
    );

    await fillValidCredentials(tester);
    await tapSignIn(tester);
    await tester.pumpAndSettle();

    expect(find.textContaining('koneksi internet'), findsOneWidget);
  });

  testWidgets('memberi tahu AuthBloc saat login berhasil', (tester) async {
    await pumpLoginScreen(tester);

    await fillValidCredentials(tester);
    await tapSignIn(tester);
    await tester.pumpAndSettle();

    expect(authBloc.state.status, AuthStatus.authenticated);
    expect(authBloc.state.session?.user.name, 'Ari Putra');
  });

  testWidgets('menyimpan sesi ke penyimpanan saat login berhasil',
      (tester) async {
    await pumpLoginScreen(tester);

    await fillValidCredentials(tester);
    await tapSignIn(tester);
    await tester.pumpAndSettle();

    expect(harness.storage.session, isNotNull);
  });

  testWidgets('menghapus pesan galat saat pengguna mencoba lagi',
      (tester) async {
    var attempt = 0;
    final releaseSecondResponse = Completer<void>();
    await pumpLoginScreen(
      tester,
      handler: (_) async {
        attempt++;
        if (attempt == 1) return AuthHarness.unauthorizedResponse();
        await releaseSecondResponse.future;
        return AuthHarness.successfulLoginResponse();
      },
    );

    await fillValidCredentials(tester);
    await tapSignIn(tester);
    await tester.pumpAndSettle();
    expect(find.text('Email atau kata sandi salah.'), findsOneWidget);

    await tapSignIn(tester);
    await tester.pump();

    expect(find.text('Email atau kata sandi salah.'), findsNothing);

    releaseSecondResponse.complete();
    await tester.pumpAndSettle();
  });
}
