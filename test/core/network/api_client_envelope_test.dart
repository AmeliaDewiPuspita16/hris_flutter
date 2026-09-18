import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:hris_mobile/core/network/api_client.dart';
import 'package:hris_mobile/core/network/api_exception.dart';

ApiClient clientThatResponds(
  Future<http.Response> Function(http.Request request) handler,
) =>
    ApiClient(httpClient: MockClient(handler));

void main() {
  group('ApiClient.getEnvelope', () {
    test('mengembalikan amplop utuh, bukan hanya isi data', () async {
      // EProcurement menaruh summary/meta BERSEBELAHAN dengan data, bukan di
      // dalamnya — get() dan getList() akan membuang keduanya.
      final client = clientThatResponds(
        (_) async => http.Response(
          jsonEncode({
            'data': [
              {'id': 9},
            ],
            'summary': {'all': 9, 'pending_hod': 1},
            'meta': {'current_page': 1, 'last_page': 5},
          }),
          200,
        ),
      );

      final envelope = await client.getEnvelope('/api/portal/apps/eprocurement');

      expect(envelope['data'], [
        {'id': 9},
      ]);
      expect(envelope['summary'], {'all': 9, 'pending_hod': 1});
      expect(envelope['meta'], {'current_page': 1, 'last_page': 5});
    });

    test('meneruskan path apa adanya ke URL, termasuk query string', () async {
      late Uri requested;
      final client = clientThatResponds((request) async {
        requested = request.url;
        return http.Response(jsonEncode({'data': <dynamic>[]}), 200);
      });

      await client.getEnvelope('/api/portal/apps/eprocurement?page=2&status=draft');

      expect(requested.path, '/api/portal/apps/eprocurement');
      expect(requested.queryParameters, {'page': '2', 'status': 'draft'});
    });

    test('melempar unauthorized saat server membalas 401', () async {
      final client = clientThatResponds(
        (_) async => http.Response(
          jsonEncode({'message': 'Token kedaluwarsa.'}),
          401,
        ),
      );

      expect(
        () => client.getEnvelope('/api/portal/apps/eprocurement'),
        throwsA(
          isA<ApiException>()
              .having((e) => e.kind, 'kind', ApiErrorKind.unauthorized),
        ),
      );
    });

    test('melempar galat server bila amplop tidak memuat data', () async {
      final client = clientThatResponds(
        (_) async => http.Response(jsonEncode({'summary': <String, int>{}}), 200),
      );

      expect(
        () => client.getEnvelope('/api/portal/apps/eprocurement'),
        throwsA(
          isA<ApiException>().having((e) => e.kind, 'kind', ApiErrorKind.server),
        ),
      );
    });
  });
}
