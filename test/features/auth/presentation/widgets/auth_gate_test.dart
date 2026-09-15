import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hris_mobile/features/auth/presentation/bloc/auth/auth_bloc.dart';
import 'package:hris_mobile/features/auth/presentation/bloc/auth/auth_event.dart';
import 'package:hris_mobile/features/auth/presentation/bloc/auth/auth_state.dart';
import 'package:hris_mobile/features/auth/presentation/screens/login_screen.dart';
import 'package:hris_mobile/features/auth/presentation/widgets/auth_gate.dart';
import 'package:hris_mobile/features/home/presentation/screens/beranda_screen.dart';
import 'package:hris_mobile/features/splash/presentation/screens/splash_screen.dart';

import '../../../../fixtures/login_response.dart';
import '../../../../support/auth_harness.dart';
import 'package:hris_mobile/features/auth/domain/auth_session.dart';

void main() {
  const splashDuration = Duration(milliseconds: 100);

  Future<AuthBloc> pumpGate(
    WidgetTester tester, {
    AuthSession? savedSession,
  }) async {
    final harness = AuthHarness();
    harness.storage.session = savedSession;
    final bloc = AuthBloc(repository: harness.repository);

    await tester.pumpWidget(
      MaterialApp(
        home: RepositoryProvider.value(
          value: harness.repository,
          child: BlocProvider.value(
            value: bloc,
            child: const AuthGate(minimumSplashDuration: splashDuration),
          ),
        ),
      ),
    );
    return bloc;
  }

  testWidgets('menampilkan splash selagi status sesi belum diketahui',
      (tester) async {
    await pumpGate(tester);

    expect(find.byType(SplashScreen), findsOneWidget);
    expect(find.byType(LoginScreen), findsNothing);

    await tester.pump(splashDuration);
  });

  testWidgets('tetap menampilkan splash sebelum durasi minimumnya lewat',
      (tester) async {
    final bloc = await pumpGate(tester);

    bloc.add(const AuthStarted());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 20));

    expect(bloc.state.status, AuthStatus.unauthenticated);
    expect(find.byType(SplashScreen), findsOneWidget);

    await tester.pump(splashDuration);
  });

  testWidgets('menampilkan login saat tidak ada sesi tersimpan',
      (tester) async {
    final bloc = await pumpGate(tester);

    bloc.add(const AuthStarted());
    await tester.pump();
    await tester.pump(splashDuration);
    await tester.pumpAndSettle();

    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.byType(SplashScreen), findsNothing);
  });

  testWidgets('menampilkan beranda saat ada sesi tersimpan', (tester) async {
    final bloc = await pumpGate(
      tester,
      savedSession: AuthSession.fromJson(loginResponseData()),
    );

    bloc.add(const AuthStarted());
    await tester.pump();
    await tester.pump(splashDuration);
    await tester.pumpAndSettle();

    expect(find.byType(BerandaScreen), findsOneWidget);
    expect(find.byType(SplashScreen), findsNothing);
  });

  testWidgets('kembali ke login setelah sesi dibatalkan', (tester) async {
    final bloc = await pumpGate(
      tester,
      savedSession: AuthSession.fromJson(loginResponseData()),
    );
    bloc.add(const AuthStarted());
    await tester.pump();
    await tester.pump(splashDuration);
    await tester.pumpAndSettle();

    bloc.add(const AuthLogoutRequested());
    await tester.pumpAndSettle();

    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.byType(BerandaScreen), findsNothing);
  });
}
