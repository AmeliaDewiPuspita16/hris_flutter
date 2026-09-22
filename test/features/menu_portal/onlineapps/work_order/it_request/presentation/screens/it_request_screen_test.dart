import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hris_mobile/features/auth/domain/auth_session.dart';
import 'package:hris_mobile/features/auth/domain/auth_user.dart';
import 'package:hris_mobile/features/auth/presentation/bloc/auth/auth_bloc.dart';
import 'package:hris_mobile/features/auth/presentation/bloc/auth/auth_event.dart';
import 'package:hris_mobile/features/auth/presentation/bloc/auth/auth_state.dart';
import 'package:hris_mobile/features/menu_portal/onlineapps/work_order/it_request/data/it_request_repository.dart';
import 'package:hris_mobile/features/menu_portal/onlineapps/work_order/it_request/presentation/screens/it_request_screen.dart';

import '../../../../../../../fixtures/it_request_response.dart';
import '../../../../../../../support/auth_harness.dart';
import '../../support/it_request_harness.dart';

void main() {
  Future<AuthBloc> authBlocWith(WidgetTester tester, List<String> roles) async {
    final harness = AuthHarness();
    harness.storage.session = AuthSession(
      token: 'token-palsu',
      user: AuthUser(id: 1, name: 'Test User', email: 'test@biie.co.id', roles: roles),
    );
    final bloc = AuthBloc(repository: harness.repository)..add(const AuthStarted());
    // `AuthStarted` diproses async (baca storage) — microtask-nya cuma
    // "dituangkan" saat widget test binding di-pump, bukan otomatis, karena
    // testWidgets berjalan di zona FakeAsync. Pola sama dengan
    // profil_logout_test.dart.
    await tester.pump();
    expect(bloc.state.status, AuthStatus.authenticated);
    return bloc;
  }

  Future<void> pumpScreen(
    WidgetTester tester, {
    required AuthBloc authBloc,
    bool? isItTeam,
  }) async {
    final itRequestHarness =
        ItRequestHarness((_, __) => ok(itRequestListEnvelope()));

    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [BlocProvider<AuthBloc>.value(value: authBloc)],
        child: RepositoryProvider<ItRequestRepository>.value(
          value: itRequestHarness.repository,
          child: MaterialApp(
            home: ItRequestScreen(isItTeam: isItTeam),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('role "it media" menampilkan tab List Request dan Report',
      (tester) async {
    final authBloc = await authBlocWith(tester, ['it media']);

    await pumpScreen(tester, authBloc: authBloc);

    expect(find.text('Form IT & Media'), findsOneWidget);
    expect(find.text('List Request'), findsOneWidget);
    expect(find.text('Report'), findsOneWidget);
  });

  testWidgets('role "admin" menampilkan tab List Request dan Report',
      (tester) async {
    final authBloc = await authBlocWith(tester, ['admin']);

    await pumpScreen(tester, authBloc: authBloc);

    expect(find.text('List Request'), findsOneWidget);
    expect(find.text('Report'), findsOneWidget);
  });

  testWidgets(
      'role selain IT Media/Admin cuma menampilkan halaman Form IT & Media '
      'tanpa tab', (tester) async {
    final authBloc = await authBlocWith(tester, ['gmo']);

    await pumpScreen(tester, authBloc: authBloc);

    expect(find.text('Form IT & Media'), findsNothing);
    expect(find.text('List Request'), findsNothing);
    expect(find.text('Report'), findsNothing);
  });

  testWidgets('tidak ada tab Approve Request lagi, walau role IT Media',
      (tester) async {
    final authBloc = await authBlocWith(tester, ['it media']);

    await pumpScreen(tester, authBloc: authBloc);

    expect(find.text('Approve Request'), findsNothing);
  });

  testWidgets('isItTeam override tetap dihormati tanpa perlu AuthBloc',
      (tester) async {
    final itRequestHarness =
        ItRequestHarness((_, __) => ok(itRequestListEnvelope()));

    await tester.pumpWidget(
      RepositoryProvider<ItRequestRepository>.value(
        value: itRequestHarness.repository,
        child: MaterialApp(
          home: ItRequestScreen(isItTeam: true),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('List Request'), findsOneWidget);  });
}
