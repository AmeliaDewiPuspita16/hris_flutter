import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:hris_mobile/core/logging/app_logger.dart';
import 'package:hris_mobile/core/network/api_client.dart';
import 'package:hris_mobile/core/network/api_config.dart';

import '../../support/log_recorder.dart';

void main() {
  late LogRecorder recorder;

  setUp(() => recorder = LogRecorder()..install());
  tearDown(AppLogger.resetSink);

  ApiClient clientThatResponds(
    Future<http.Response> Function(http.Request request) handler,
  ) {
    return ApiClient(httpClient: MockClient(handler));
  }

  String okEnvelope() => jsonEncode({
        'code': 200,
        'status': 'success',
        'message': 'Authenticated',
        'data': {'access_token': 'rahasia-token'},
      });

  test('mencatat metode dan URL request', () async {
    final client = clientThatResponds(
      (_) async => http.Response(okEnvelope(), 200),
    );

    await client.post(ApiConfig.login, body: {'email': 'a@biie.co.id'});

    expect(recorder.combined, contains('POST'));
    expect(recorder.combined, contains('${ApiConfig.baseUrl}/api/login'));
  });

  test('mencatat kode status respons', () async {
    final client = clientThatResponds(
      (_) async => http.Response(okEnvelope(), 200),
    );

    await client.post(ApiConfig.login);

    expect(recorder.combined, contains('200'));
  });

  test('tidak pernah mencatat password', () async {
    final client = clientThatResponds(
      (_) async => http.Response(okEnvelope(), 200),
    );

    await client.post(
      ApiConfig.login,
      body: {'email': 'ariputra@biie.co.id', 'password': 'liveismagic'},
    );

    expect(recorder.combined, isNot(contains('liveismagic')));
    expect(recorder.combined, contains('ariputra@biie.co.id'));
  });

  test('tidak pernah mencatat isi token', () async {
    final client = clientThatResponds(
      (_) async => http.Response(okEnvelope(), 200),
    );
    client.setToken('9256|OgtFbm3nXkTzwpj9');

    await client.post('/api/profile');

    expect(recorder.combined, isNot(contains('OgtFbm3nXkTzwpj9')));
  });

  test('mencatat badan respons saat server membalas galat', () async {
    final client = clientThatResponds(
      (_) async => http.Response(
        jsonEncode({'status': 'error', 'message': 'Invalid credentials'}),
        401,
      ),
    );

    await expectLater(client.post(ApiConfig.login), throwsA(anything));

    expect(recorder.combined, contains('401'));
    expect(recorder.combined, contains('Invalid credentials'));
  });

  group('respons 2xx yang bentuknya tak terduga', () {
    test('mencatat badan respons saat amplop tidak bisa dipahami', () async {
      final client = clientThatResponds(
        (_) async => http.Response('<html><body>Maintenance</body></html>', 200),
      );

      await expectLater(client.post(ApiConfig.login), throwsA(anything));

      expect(recorder.combined, contains('Maintenance'));
    });

    test('mencatat bentuk data saat list diharapkan tapi objek yang datang',
        () async {
      final client = clientThatResponds(
        (_) async => http.Response(
          jsonEncode({
            'code': 200,
            'status': 'success',
            'message': 'OK',
            'data': {
              'departments': [
                {'id': 18, 'name': 'IT'},
              ],
            },
          }),
          200,
        ),
      );

      await expectLater(
        client.getList('/api/data/department'),
        throwsA(anything),
      );

      // Isi data ikut tercatat supaya bentuk sebenarnya langsung kelihatan.
      expect(recorder.combined, contains('departments'));
    });

    test('mencatat bentuk data saat objek diharapkan tapi list yang datang',
        () async {
      final client = clientThatResponds(
        (_) async => http.Response(
          jsonEncode({
            'code': 200,
            'status': 'success',
            'message': 'OK',
            'data': [1, 2, 3],
          }),
          200,
        ),
      );

      await expectLater(client.get('/api/profile'), throwsA(anything));

      expect(recorder.combined, contains('List'));
    });

    test('mencatat pesan server saat status bukan success', () async {
      final client = clientThatResponds(
        (_) async => http.Response(
          jsonEncode({'code': 200, 'status': 'error', 'message': 'Akun nonaktif'}),
          200,
        ),
      );

      await expectLater(client.post(ApiConfig.login), throwsA(anything));

      expect(recorder.combined, contains('Akun nonaktif'));
    });
  });

  test('mencatat kegagalan jaringan beserta penyebab aslinya', () async {
    final client = clientThatResponds(
      (_) async => throw http.ClientException('Connection refused'),
    );

    await expectLater(client.post(ApiConfig.login), throwsA(anything));

    expect(
      recorder.entries.any((e) => e.error is http.ClientException),
      isTrue,
    );
  });
}
