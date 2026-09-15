import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:hris_mobile/core/network/api_client.dart';
import 'package:hris_mobile/core/network/api_config.dart';
import 'package:hris_mobile/core/network/api_exception.dart';

/// Membuat ApiClient yang setiap request-nya dilayani [handler].
ApiClient clientThatResponds(
  Future<http.Response> Function(http.Request request) handler, {
  Duration? timeout,
}) {
  return ApiClient(httpClient: MockClient(handler), timeout: timeout);
}

/// Amplop sukses seperti yang dikembalikan BIIE Portal.
String successEnvelope(Map<String, dynamic> data) => jsonEncode({
      'code': 200,
      'status': 'success',
      'message': 'Authenticated',
      'data': data,
    });

void main() {
  group('ApiClient.post', () {
    test('mengembalikan isi data dari amplop respons', () async {
      final client = clientThatResponds(
        (_) async => http.Response(
          successEnvelope({'access_token': 'abc123'}),
          200,
        ),
      );

      final data = await client.post(ApiConfig.login);

      expect(data, {'access_token': 'abc123'});
    });

    test('menyusun URL dari base URL dan path', () async {
      late Uri requested;
      final client = clientThatResponds((request) async {
        requested = request.url;
        return http.Response(successEnvelope(const {}), 200);
      });

      await client.post('/api/login');

      expect(requested, Uri.parse('${ApiConfig.baseUrl}/api/login'));
    });

    test('mengirim body sebagai JSON dengan Content-Type yang benar',
        () async {
      late http.Request sent;
      final client = clientThatResponds((request) async {
        sent = request;
        return http.Response(successEnvelope(const {}), 200);
      });

      await client.post(
        ApiConfig.login,
        body: {'email': 'ariputra@biie.co.id', 'password': 'rahasia'},
      );

      expect(sent.headers['Content-Type'], contains('application/json'));
      expect(jsonDecode(sent.body), {
        'email': 'ariputra@biie.co.id',
        'password': 'rahasia',
      });
    });

    test('tidak mengirim header Authorization sebelum token diset', () async {
      late http.Request sent;
      final client = clientThatResponds((request) async {
        sent = request;
        return http.Response(successEnvelope(const {}), 200);
      });

      await client.post(ApiConfig.login);

      expect(sent.headers.containsKey('Authorization'), isFalse);
    });

    test('memasang header Bearer setelah setToken', () async {
      late http.Request sent;
      final client = clientThatResponds((request) async {
        sent = request;
        return http.Response(successEnvelope(const {}), 200);
      });
      client.setToken('9256|OgtFbm3nXkTz');

      await client.post('/api/profile');

      expect(sent.headers['Authorization'], 'Bearer 9256|OgtFbm3nXkTz');
    });

    test('memakai tokenType dari server, bukan string Bearer yang dipatok',
        () async {
      late http.Request sent;
      final client = clientThatResponds((request) async {
        sent = request;
        return http.Response(successEnvelope(const {}), 200);
      });
      client.setToken('abc123', tokenType: 'Token');

      await client.post('/api/profile');

      expect(sent.headers['Authorization'], 'Token abc123');
    });

    test('melepas header Authorization saat token dihapus', () async {
      late http.Request sent;
      final client = clientThatResponds((request) async {
        sent = request;
        return http.Response(successEnvelope(const {}), 200);
      });
      client.setToken('abc123');
      client.setToken(null);

      await client.post('/api/profile');

      expect(sent.headers.containsKey('Authorization'), isFalse);
    });

    test('tidak memasang Authorization saat authenticated bernilai false',
        () async {
      late http.Request sent;
      final client = clientThatResponds((request) async {
        sent = request;
        return http.Response(successEnvelope(const {}), 200);
      });
      client.setToken('abc123');

      await client.post(ApiConfig.login, authenticated: false);

      expect(sent.headers.containsKey('Authorization'), isFalse);
    });
  });

  group('ApiClient penanganan error', () {
    test('memetakan 401 ke ApiErrorKind.unauthorized', () async {
      final client = clientThatResponds(
        (_) async => http.Response(
          jsonEncode({
            'code': 401,
            'status': 'error',
            'message': 'Invalid credentials',
          }),
          401,
        ),
      );

      await expectLater(
        client.post(ApiConfig.login),
        throwsA(
          isA<ApiException>()
              .having((e) => e.kind, 'kind', ApiErrorKind.unauthorized),
        ),
      );
    });

    test('memakai pesan server pada respons 401', () async {
      final client = clientThatResponds(
        (_) async => http.Response(
          jsonEncode({'status': 'error', 'message': 'Kredensial tidak cocok'}),
          401,
        ),
      );

      await expectLater(
        client.post(ApiConfig.login),
        throwsA(
          isA<ApiException>()
              .having((e) => e.message, 'message', 'Kredensial tidak cocok'),
        ),
      );
    });

    test('memakai pesan validasi pertama pada respons 422', () async {
      final client = clientThatResponds(
        (_) async => http.Response(
          jsonEncode({
            'message': 'The given data was invalid.',
            'errors': {
              'email': ['Email tidak terdaftar.'],
              'password': ['Kata sandi terlalu pendek.'],
            },
          }),
          422,
        ),
      );

      await expectLater(
        client.post(ApiConfig.login),
        throwsA(
          isA<ApiException>()
              .having((e) => e.kind, 'kind', ApiErrorKind.badRequest)
              .having((e) => e.message, 'message', 'Email tidak terdaftar.'),
        ),
      );
    });

    test('memetakan 500 ke ApiErrorKind.server', () async {
      final client = clientThatResponds(
        (_) async => http.Response('Internal Server Error', 500),
      );

      await expectLater(
        client.post(ApiConfig.login),
        throwsA(
          isA<ApiException>()
              .having((e) => e.kind, 'kind', ApiErrorKind.server),
        ),
      );
    });

    test('memetakan respons HTML yang bukan JSON ke ApiErrorKind.server',
        () async {
      final client = clientThatResponds(
        (_) async => http.Response('<html><body>Oops</body></html>', 200),
      );

      await expectLater(
        client.post(ApiConfig.login),
        throwsA(
          isA<ApiException>()
              .having((e) => e.kind, 'kind', ApiErrorKind.server),
        ),
      );
    });

    test('menolak HTTP 200 yang status-nya bukan success', () async {
      final client = clientThatResponds(
        (_) async => http.Response(
          jsonEncode({
            'code': 200,
            'status': 'error',
            'message': 'Akun Anda dinonaktifkan',
          }),
          200,
        ),
      );

      await expectLater(
        client.post(ApiConfig.login),
        throwsA(
          isA<ApiException>()
              .having((e) => e.message, 'message', 'Akun Anda dinonaktifkan'),
        ),
      );
    });

    test('menolak amplop sukses yang tidak punya objek data', () async {
      final client = clientThatResponds(
        (_) async => http.Response(
          jsonEncode({'code': 200, 'status': 'success', 'message': 'OK'}),
          200,
        ),
      );

      await expectLater(
        client.post(ApiConfig.login),
        throwsA(
          isA<ApiException>()
              .having((e) => e.kind, 'kind', ApiErrorKind.server),
        ),
      );
    });

    test('memetakan kegagalan soket ke ApiErrorKind.network', () async {
      final client = clientThatResponds(
        (_) async => throw const SocketException('No route to host'),
      );

      await expectLater(
        client.post(ApiConfig.login),
        throwsA(
          isA<ApiException>()
              .having((e) => e.kind, 'kind', ApiErrorKind.network),
        ),
      );
    });

    test('memetakan ClientException ke ApiErrorKind.network', () async {
      final client = clientThatResponds(
        (_) async => throw http.ClientException('Connection closed'),
      );

      await expectLater(
        client.post(ApiConfig.login),
        throwsA(
          isA<ApiException>()
              .having((e) => e.kind, 'kind', ApiErrorKind.network),
        ),
      );
    });

    test('memetakan request yang kelewat lama ke ApiErrorKind.network',
        () async {
      final client = clientThatResponds(
        (_) async {
          await Future<void>.delayed(const Duration(milliseconds: 200));
          return http.Response(successEnvelope(const {}), 200);
        },
        timeout: const Duration(milliseconds: 20),
      );

      await expectLater(
        client.post(ApiConfig.login),
        throwsA(
          isA<ApiException>()
              .having((e) => e.kind, 'kind', ApiErrorKind.network)
              .having((e) => e.message, 'message', contains('tidak merespons')),
        ),
      );
    });
  });
}
