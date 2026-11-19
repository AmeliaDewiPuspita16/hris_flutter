import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:hris_mobile/core/logging/app_logger.dart';
import 'package:hris_mobile/features/auth/domain/auth_session.dart';
import 'package:hris_mobile/features/auth/presentation/bloc/auth/auth_bloc.dart';
import 'package:hris_mobile/features/auth/presentation/bloc/auth/auth_event.dart';
import 'package:hris_mobile/features/auth/presentation/bloc/auth/auth_state.dart';

import '../../../../fixtures/login_response.dart';
import '../../../../support/auth_harness.dart';
import '../../../../support/log_recorder.dart';

void main() {
  AuthSession savedSession() => AuthSession.fromJson(loginResponseData());

  Matcher hasStatus(AuthStatus status) =>
      isA<AuthState>().having((s) => s.status, 'status', status);

  test('mulai dari status unknown supaya splash yang tampil lebih dulu', () {
    final bloc = AuthBloc(repository: AuthHarness().repository);

    expect(bloc.state.status, AuthStatus.unknown);
  });

  group('AuthStarted', () {
    test('menjadi unauthenticated saat tidak ada sesi tersimpan', () async {
      final bloc = AuthBloc(repository: AuthHarness().repository);

      final expectation = expectLater(
        bloc.stream,
        emits(hasStatus(AuthStatus.unauthenticated)),
      );
      bloc.add(const AuthStarted());

      await expectation;
    });

    test('menjadi authenticated saat ada sesi tersimpan', () async {
      final harness = AuthHarness();
      harness.storage.session = savedSession();
      final bloc = AuthBloc(repository: harness.repository);

      final expectation = expectLater(
        bloc.stream,
        emits(
          isA<AuthState>()
              .having((s) => s.status, 'status', AuthStatus.authenticated)
              .having(
                (s) => s.session?.user.email,
                'email',
                'ariputra@biie.co.id',
              ),
        ),
      );
      bloc.add(const AuthStarted());

      await expectation;
    });

    test('memasang token sesi tersimpan ke ApiClient', () async {
      final harness = AuthHarness();
      harness.storage.session = savedSession();
      final bloc = AuthBloc(repository: harness.repository);

      bloc.add(const AuthStarted());
      await bloc.stream.first;

      expect(
        harness.apiClient.authorizationHeader,
        'Bearer ${savedSession().token}',
      );
    });

    test('tetap unauthenticated saat penyimpanan tidak bisa dibaca', () async {
      final harness = AuthHarness();
      harness.storage.failOnRead = true;
      final bloc = AuthBloc(repository: harness.repository);

      final expectation = expectLater(
        bloc.stream,
        emits(hasStatus(AuthStatus.unauthenticated)),
      );
      bloc.add(const AuthStarted());

      await expectation;
    });

    test('mencatat ke console saat penyimpanan tidak bisa dibaca', () async {
      final recorder = LogRecorder()..install();
      addTearDown(AppLogger.resetSink);

      final harness = AuthHarness();
      harness.storage.failOnRead = true;
      final bloc = AuthBloc(repository: harness.repository);

      bloc.add(const AuthStarted());
      await bloc.stream.first;

      final logged = recorder.entries.where((e) => e.error != null);
      expect(logged, isNotEmpty);
      expect(logged.last.error, isA<StateError>());
      expect(logged.last.stackTrace, isNotNull);
    });
  });

  test('AuthSessionGranted menjadikan status authenticated', () async {
    final bloc = AuthBloc(repository: AuthHarness().repository);
    final session = savedSession();

    final expectation = expectLater(
      bloc.stream,
      emits(
        isA<AuthState>()
            .having((s) => s.status, 'status', AuthStatus.authenticated)
            .having((s) => s.session, 'sesi', same(session)),
      ),
    );
    bloc.add(AuthSessionGranted(session));

    await expectation;
  });

  group('AuthLogoutRequested', () {
    test('menjadi unauthenticated dan membersihkan penyimpanan', () async {
      final harness = AuthHarness();
      harness.storage.session = savedSession();
      final bloc = AuthBloc(repository: harness.repository);
      bloc.add(const AuthStarted());
      await bloc.stream.first;

      final expectation = expectLater(
        bloc.stream,
        emits(hasStatus(AuthStatus.unauthenticated)),
      );
      bloc.add(const AuthLogoutRequested());
      await expectation;

      expect(harness.storage.session, isNull);
      expect(harness.storage.clearCount, 1);
      expect(harness.apiClient.authorizationHeader, isNull);
    });
  });

  group('AuthSessionExpired', () {
    test('menjadi unauthenticated dan membuang sesi yang tidak berlaku',
        () async {
      final harness = AuthHarness();
      harness.storage.session = savedSession();
      final bloc = AuthBloc(repository: harness.repository);
      bloc.add(const AuthStarted());
      await bloc.stream.first;

      final expectation = expectLater(
        bloc.stream,
        emits(hasStatus(AuthStatus.unauthenticated)),
      );
      bloc.add(const AuthSessionExpired());
      await expectation;

      expect(harness.storage.session, isNull);
      expect(harness.apiClient.authorizationHeader, isNull);
    });

    test('menandai state sebagai sessionExpired', () async {
      final harness = AuthHarness();
      harness.storage.session = savedSession();
      final bloc = AuthBloc(repository: harness.repository);
      bloc.add(const AuthStarted());
      await bloc.stream.first;

      bloc.add(const AuthSessionExpired());
      final state = await bloc.stream.first;

      expect(state.sessionExpired, isTrue);
    });

    test('tidak menghubungi server (logout / cabut FCM)', () async {
      final requests = <http.Request>[];
      final harness = AuthHarness(handler: (request) async {
        requests.add(request);
        return AuthHarness.successfulLoginResponse();
      });
      harness.storage.session = savedSession();
      final bloc = AuthBloc(repository: harness.repository);
      bloc.add(const AuthStarted());
      await bloc.stream.first;

      bloc.add(const AuthSessionExpired());
      await bloc.stream.first;

      expect(requests, isEmpty);
    });

    test('401 dari API mana pun mengeluarkan pengguna, sekali saja', () async {
      final harness = AuthHarness(
        handler: (_) async => http.Response(
          jsonEncode({'message': 'Unauthenticated.'}),
          401,
        ),
      );
      harness.storage.session = savedSession();
      final bloc = AuthBloc(repository: harness.repository);
      bloc.add(const AuthStarted());
      await bloc.stream.first;

      final states = <AuthState>[];
      final sub = bloc.stream.listen(states.add);

      // Seperti Beranda: beberapa request gagal hampir bersamaan.
      await Future.wait([
        for (var i = 0; i < 3; i++)
          harness.apiClient.get('/api/x').then((_) {}, onError: (_) {}),
      ]);
      await Future<void>.delayed(const Duration(milliseconds: 10));
      await sub.cancel();

      expect(states, hasLength(1));
      expect(states.single.status, AuthStatus.unauthenticated);
      expect(states.single.sessionExpired, isTrue);
      expect(harness.storage.session, isNull);
    });
  });

  test('logout biasa tidak menandai sessionExpired', () async {
    final harness = AuthHarness();
    harness.storage.session = savedSession();
    final bloc = AuthBloc(repository: harness.repository);
    bloc.add(const AuthStarted());
    await bloc.stream.first;

    bloc.add(const AuthLogoutRequested());
    final state = await bloc.stream.first;

    expect(state.sessionExpired, isFalse);
  });
}
