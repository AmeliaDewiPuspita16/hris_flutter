import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:hris_mobile/core/network/api_client.dart';
import 'package:hris_mobile/core/network/api_exception.dart';

http.Response _status(int code) => http.Response(
      jsonEncode({'message': code == 401 ? 'Unauthenticated.' : 'Forbidden'}),
      code,
    );

/// Menghitung berapa kali [ApiClient.onSessionExpired] berbunyi.
class _Counter {
  _Counter(ApiClient client) {
    _sub = client.onSessionExpired.listen((_) => count++);
  }

  late final StreamSubscription<void> _sub;
  int count = 0;

  Future<void> settle() async {
    await Future<void>.delayed(Duration.zero);
    await _sub.cancel();
  }
}

void main() {
  test('401 pada request bertoken memicu onSessionExpired', () async {
    final client = ApiClient(httpClient: MockClient((_) async => _status(401)))
      ..setToken('abc');
    final counter = _Counter(client);

    await expectLater(
      client.get('/api/portal/home'),
      throwsA(isA<ApiException>()
          .having((e) => e.kind, 'kind', ApiErrorKind.unauthorized)),
    );
    await counter.settle();

    expect(counter.count, 1);
  });

  test('berlaku juga untuk metode tanpa amplop (getJson)', () async {
    final client = ApiClient(httpClient: MockClient((_) async => _status(401)))
      ..setToken('abc');
    final counter = _Counter(client);

    await expectLater(
        client.getJson('/api/est/x'), throwsA(isA<ApiException>()));
    await counter.settle();

    expect(counter.count, 1);
  });

  test('403 tidak dianggap sesi berakhir', () async {
    final client = ApiClient(httpClient: MockClient((_) async => _status(403)))
      ..setToken('abc');
    final counter = _Counter(client);

    await expectLater(client.get('/api/x'), throwsA(isA<ApiException>()));
    await counter.settle();

    expect(counter.count, 0);
  });

  test('401 tanpa token (mis. login gagal) tidak memicu', () async {
    final client = ApiClient(httpClient: MockClient((_) async => _status(401)));
    final counter = _Counter(client);

    await expectLater(client.post('/api/login'), throwsA(isA<ApiException>()));
    await counter.settle();

    expect(counter.count, 0);
  });

  test('401 pada request authenticated:false tidak memicu', () async {
    final client = ApiClient(httpClient: MockClient((_) async => _status(401)))
      ..setToken('abc');
    final counter = _Counter(client);

    await expectLater(
      client.post('/api/login', authenticated: false),
      throwsA(isA<ApiException>()),
    );
    await counter.settle();

    expect(counter.count, 0);
  });

  test('401 dari token lama setelah token diganti tidak memicu', () async {
    final respond = Completer<http.Response>();
    final client = ApiClient(httpClient: MockClient((_) => respond.future))
      ..setToken('lama');
    final counter = _Counter(client);

    final request = client.get('/api/x');
    await Future<void>.delayed(Duration.zero);
    client.setToken('baru');
    respond.complete(_status(401));

    await expectLater(request, throwsA(isA<ApiException>()));
    await counter.settle();

    expect(counter.count, 0);
  });
}
