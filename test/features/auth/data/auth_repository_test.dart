import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:hris_mobile/core/logging/app_logger.dart';
import 'package:hris_mobile/core/network/api_client.dart';
import 'package:hris_mobile/core/network/api_exception.dart';
import 'package:hris_mobile/features/auth/data/auth_repository.dart';
import 'package:hris_mobile/features/auth/domain/auth_session.dart';

import '../../../fixtures/login_response.dart';
import '../../../support/fake_session_storage.dart';
import '../../../support/log_recorder.dart';

void main() {
  late FakeSessionStorage storage;

  setUp(() => storage = FakeSessionStorage());

  /// Repository yang setiap request HTTP-nya dilayani [handler].
  ({AuthRepository repository, ApiClient apiClient}) buildRepository(
    Future<http.Response> Function(http.Request request) handler,
  ) {
    final apiClient = ApiClient(httpClient: MockClient(handler));
    return (
      repository: AuthRepository(apiClient: apiClient, storage: storage),
      apiClient: apiClient,
    );
  }

  http.Response okLogin() =>
      http.Response(jsonEncode(loginResponseEnvelope()), 200);

  group('AuthRepository.login', () {
    test('mengirim email dan password ke endpoint login', () async {
      late http.Request sent;
      final built = buildRepository((request) async {
        sent = request;
        return okLogin();
      });

      await built.repository.login(
        email: 'ariputra@biie.co.id',
        password: 'rahasia',
      );

      expect(sent.url.path, '/api/login');
      expect(jsonDecode(sent.body), {
        'email': 'ariputra@biie.co.id',
        'password': 'rahasia',
      });
    });

    test('mengembalikan sesi hasil parsing respons server', () async {
      final built = buildRepository((_) async => okLogin());

      final session = await built.repository.login(
        email: 'ariputra@biie.co.id',
        password: 'rahasia',
      );

      expect(session.token, startsWith('9999|'));
      expect(session.user.name, 'Ari Putra');
      expect(session.user.roles, contains('it media'));
    });

    test('menyimpan sesi ke penyimpanan saat login berhasil', () async {
      final built = buildRepository((_) async => okLogin());

      await built.repository.login(
        email: 'ariputra@biie.co.id',
        password: 'rahasia',
      );

      expect(storage.session, isNotNull);
      expect(storage.session!.user.email, 'ariputra@biie.co.id');
    });

    test('memasang token ke ApiClient saat login berhasil', () async {
      final built = buildRepository((_) async => okLogin());

      final session = await built.repository.login(
        email: 'ariputra@biie.co.id',
        password: 'rahasia',
      );

      expect(built.apiClient.authorizationHeader, 'Bearer ${session.token}');
    });

    test('tidak mengirim token lama pada request login', () async {
      late http.Request sent;
      final built = buildRepository((request) async {
        sent = request;
        return okLogin();
      });
      built.apiClient.setToken('token-kedaluwarsa');

      await built.repository.login(
        email: 'ariputra@biie.co.id',
        password: 'rahasia',
      );

      expect(sent.headers.containsKey('Authorization'), isFalse);
    });

    test('memberi pesan kredensial salah saat server membalas 401', () async {
      final built = buildRepository(
        (_) async => http.Response(
          jsonEncode({'status': 'error', 'message': 'Invalid credentials'}),
          401,
        ),
      );

      await expectLater(
        built.repository.login(email: 'a@biie.co.id', password: 'salah'),
        throwsA(
          isA<ApiException>()
              .having((e) => e.kind, 'kind', ApiErrorKind.unauthorized)
              .having(
                (e) => e.message,
                'message',
                'Email atau kata sandi salah.',
              ),
        ),
      );
    });

    test('tidak menyimpan sesi saat login gagal', () async {
      final built = buildRepository((_) async => http.Response('{}', 401));

      await expectLater(
        built.repository.login(email: 'a@biie.co.id', password: 'salah'),
        throwsA(isA<ApiException>()),
      );
      expect(storage.session, isNull);
      expect(built.apiClient.authorizationHeader, isNull);
    });

    test('meneruskan kegagalan jaringan apa adanya', () async {
      final built = buildRepository(
        (_) async => throw http.ClientException('Connection closed'),
      );

      await expectLater(
        built.repository.login(email: 'a@biie.co.id', password: 'x'),
        throwsA(
          isA<ApiException>()
              .having((e) => e.kind, 'kind', ApiErrorKind.network),
        ),
      );
    });

    test('mengubah respons sukses tanpa access_token jadi galat server',
        () async {
      final built = buildRepository(
        (_) async => http.Response(
          jsonEncode({
            'code': 200,
            'status': 'success',
            'message': 'Authenticated',
            'data': {'user': loginResponseUser()},
          }),
          200,
        ),
      );

      await expectLater(
        built.repository.login(email: 'a@biie.co.id', password: 'x'),
        throwsA(
          isA<ApiException>()
              .having((e) => e.kind, 'kind', ApiErrorKind.server),
        ),
      );
      expect(storage.session, isNull);
    });
  });

  group('AuthRepository.restoreSession', () {
    test('mengembalikan null saat belum pernah login', () async {
      final built = buildRepository((_) async => okLogin());

      expect(await built.repository.restoreSession(), isNull);
      expect(built.apiClient.authorizationHeader, isNull);
    });

    test('mengembalikan sesi tersimpan dan memasang token-nya', () async {
      storage.session = AuthSession.fromJson(loginResponseData());
      final built = buildRepository((_) async => okLogin());

      final session = await built.repository.restoreSession();

      expect(session!.user.email, 'ariputra@biie.co.id');
      expect(built.apiClient.authorizationHeader, 'Bearer ${session.token}');
    });
  });

  group('AuthRepository.logout', () {
    http.Response okLogout() => http.Response(
          jsonEncode({
            'code': 200,
            'status': 'success',
            'message': 'Token Revoked',
            'data': true,
          }),
          200,
        );

    test('menghapus sesi tersimpan dan melepas token', () async {
      storage.session = AuthSession.fromJson(loginResponseData());
      final built = buildRepository((_) async => okLogout());
      await built.repository.restoreSession();

      await built.repository.logout();

      expect(storage.session, isNull);
      expect(storage.clearCount, 1);
      expect(built.apiClient.authorizationHeader, isNull);
    });

    test('memanggil endpoint logout dengan token yang sedang berlaku',
        () async {
      storage.session = AuthSession.fromJson(loginResponseData());
      late http.Request sent;
      final built = buildRepository((request) async {
        sent = request;
        return okLogout();
      });
      await built.repository.restoreSession();

      await built.repository.logout();

      expect(sent.method, 'POST');
      expect(sent.url.path, '/api/logout');
      expect(
        sent.headers['Authorization'],
        'Bearer ${AuthSession.fromJson(loginResponseData()).token}',
      );
    });

    test('tetap membersihkan sesi saat server menolak permintaan logout',
        () async {
      storage.session = AuthSession.fromJson(loginResponseData());
      final built = buildRepository(
        (_) async => http.Response(
          jsonEncode({'status': 'error', 'message': 'Unauthenticated'}),
          401,
        ),
      );
      await built.repository.restoreSession();

      await built.repository.logout();

      expect(storage.session, isNull);
      expect(built.apiClient.authorizationHeader, isNull);
    });

    test('tetap membersihkan sesi saat perangkat sedang offline', () async {
      storage.session = AuthSession.fromJson(loginResponseData());
      final built = buildRepository(
        (_) async => throw http.ClientException('Connection refused'),
      );
      await built.repository.restoreSession();

      await built.repository.logout();

      expect(storage.session, isNull);
      expect(built.apiClient.authorizationHeader, isNull);
    });

    test('mencatat bahwa kegagalan logout di server sengaja diabaikan',
        () async {
      final recorder = LogRecorder()..install();
      addTearDown(AppLogger.resetSink);

      storage.session = AuthSession.fromJson(loginResponseData());
      final built = buildRepository(
        (_) async => throw http.ClientException('Connection refused'),
      );
      await built.repository.restoreSession();

      await built.repository.logout();

      expect(recorder.combined, contains('sesi lokal tetap dihapus'));
    });

    test('tidak memanggil server saat memang belum ada sesi', () async {
      var requestCount = 0;
      final built = buildRepository((_) async {
        requestCount++;
        return okLogout();
      });

      await built.repository.logout();

      expect(requestCount, 0);
      expect(storage.clearCount, 1);
    });
  });
}
