import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hris_mobile/features/auth/domain/auth_session.dart';
import 'package:hris_mobile/features/auth/presentation/bloc/auth/auth_bloc.dart';
import 'package:hris_mobile/features/auth/presentation/bloc/auth/auth_event.dart';
import 'package:hris_mobile/features/auth/presentation/bloc/auth/auth_state.dart';
import 'package:hris_mobile/features/profil/presentation/screens/profil_screen.dart';
import 'package:hris_mobile/features/shared/domain/role.dart';

import '../../../../fixtures/login_response.dart';
import '../../../../support/auth_harness.dart';

void main() {
  testWidgets('tombol Logout mengakhiri sesi lewat AuthBloc', (tester) async {
    final harness = AuthHarness();
    harness.storage.session = AuthSession.fromJson(loginResponseData());
    final authBloc = AuthBloc(repository: harness.repository);
    authBloc.add(const AuthStarted());
    await tester.pump();

    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider.value(
          value: authBloc,
          child: const Scaffold(body: ProfilScreen(role: Role.hrPublisher)),
        ),
      ),
    );

    await tester.scrollUntilVisible(find.text('Logout'), 300);
    await tester.tap(find.text('Logout'));
    await tester.pumpAndSettle();

    expect(authBloc.state.status, AuthStatus.unauthenticated);
    expect(harness.storage.session, isNull);
    expect(harness.apiClient.authorizationHeader, isNull);
  });
}
