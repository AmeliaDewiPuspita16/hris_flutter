import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:hris_mobile/core/logging/app_logger.dart';
import 'package:hris_mobile/features/auth/presentation/bloc/login/login_bloc.dart';
import 'package:hris_mobile/features/auth/presentation/bloc/login/login_event.dart';
import 'package:hris_mobile/features/auth/presentation/bloc/login/login_state.dart';

import '../../../../support/auth_harness.dart';
import '../../../../support/log_recorder.dart';

void main() {
  const credentials = LoginSubmitted(
    email: 'ariputra@biie.co.id',
    password: 'rahasia',
  );

  Matcher hasStatus(LoginStatus status) =>
      isA<LoginState>().having((s) => s.status, 'status', status);

  test('mulai dari keadaan initial', () {
    final bloc = LoginBloc(repository: AuthHarness().repository);

    expect(bloc.state.status, LoginStatus.initial);
    expect(bloc.state.errorMessage, isNull);
  });

  test('memancarkan loading lalu success saat kredensial diterima', () async {
    final bloc = LoginBloc(repository: AuthHarness().repository);

    final expectation = expectLater(
      bloc.stream,
      emitsInOrder([hasStatus(LoginStatus.loading), hasStatus(LoginStatus.success)]),
    );
    bloc.add(credentials);

    await expectation;
  });

  test('membawa sesi hasil login pada state success', () async {
    final bloc = LoginBloc(repository: AuthHarness().repository);

    final expectation = expectLater(
      bloc.stream,
      emitsInOrder([
        hasStatus(LoginStatus.loading),
        isA<LoginState>()
            .having((s) => s.session?.user.name, 'nama user', 'Ari Putra')
            .having((s) => s.session?.token, 'token', startsWith('9999|')),
      ]),
    );
    bloc.add(credentials);

    await expectation;
  });

  test('memancarkan failure dengan pesan kredensial salah saat 401', () async {
    final harness = AuthHarness(
      handler: (_) async => AuthHarness.unauthorizedResponse(),
    );
    final bloc = LoginBloc(repository: harness.repository);

    final expectation = expectLater(
      bloc.stream,
      emitsInOrder([
        hasStatus(LoginStatus.loading),
        isA<LoginState>()
            .having((s) => s.status, 'status', LoginStatus.failure)
            .having(
              (s) => s.errorMessage,
              'pesan',
              'Email atau kata sandi salah.',
            ),
      ]),
    );
    bloc.add(credentials);

    await expectation;
  });

  test('memakai pesan jaringan saat koneksi gagal', () async {
    final harness = AuthHarness(
      handler: (_) async => throw http.ClientException('Connection closed'),
    );
    final bloc = LoginBloc(repository: harness.repository);

    final expectation = expectLater(
      bloc.stream,
      emitsInOrder([
        hasStatus(LoginStatus.loading),
        isA<LoginState>().having(
          (s) => s.errorMessage,
          'pesan',
          contains('koneksi internet'),
        ),
      ]),
    );
    bloc.add(credentials);

    await expectation;
  });

  test('tidak membocorkan galat tak terduga sebagai pesan mentah', () async {
    final harness = AuthHarness(
      handler: (_) async => throw ArgumentError('kesalahan internal'),
    );
    final bloc = LoginBloc(repository: harness.repository);

    final expectation = expectLater(
      bloc.stream,
      emitsInOrder([
        hasStatus(LoginStatus.loading),
        isA<LoginState>()
            .having((s) => s.status, 'status', LoginStatus.failure)
            .having(
              (s) => s.errorMessage,
              'pesan',
              isNot(contains('kesalahan internal')),
            ),
      ]),
    );
    bloc.add(credentials);

    await expectation;
  });

  test('mencatat galat tak terduga ke console beserta stack trace', () async {
    final recorder = LogRecorder()..install();
    addTearDown(AppLogger.resetSink);

    final failure = StateError('keychain tidak bisa ditulis');
    final harness = AuthHarness(handler: (_) async => throw failure);
    final bloc = LoginBloc(repository: harness.repository);

    bloc.add(credentials);
    await bloc.stream.firstWhere((s) => s.status == LoginStatus.failure);

    final logged = recorder.entries.where((e) => e.error != null);
    expect(logged, isNotEmpty);
    expect(logged.last.error, same(failure));
    expect(logged.last.stackTrace, isNotNull);
  });

  test('LoginReset mengembalikan form ke keadaan initial', () async {
    final harness = AuthHarness(
      handler: (_) async => AuthHarness.unauthorizedResponse(),
    );
    final bloc = LoginBloc(repository: harness.repository);

    bloc.add(credentials);
    await bloc.stream.firstWhere((s) => s.status == LoginStatus.failure);

    final expectation = expectLater(
      bloc.stream,
      emits(
        isA<LoginState>()
            .having((s) => s.status, 'status', LoginStatus.initial)
            .having((s) => s.errorMessage, 'pesan', isNull),
      ),
    );
    bloc.add(const LoginReset());

    await expectation;
  });

  test('mengabaikan submit kedua selagi yang pertama masih berjalan',
      () async {
    var requestCount = 0;
    final firstRequestArrived = Completer<void>();
    final releaseFirstRequest = Completer<void>();

    final harness = AuthHarness(
      handler: (_) async {
        requestCount++;
        if (!firstRequestArrived.isCompleted) firstRequestArrived.complete();
        await releaseFirstRequest.future;
        return AuthHarness.successfulLoginResponse();
      },
    );
    final bloc = LoginBloc(repository: harness.repository);

    bloc.add(credentials);
    await firstRequestArrived.future;
    bloc.add(credentials);
    releaseFirstRequest.complete();
    await bloc.stream.firstWhere((s) => s.status == LoginStatus.success);

    expect(requestCount, 1);
  });
}
