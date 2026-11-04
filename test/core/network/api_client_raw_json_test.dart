import 'dart:convert';
import 'dart:io';

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
  group('ApiClient raw JSON', () {
    test('getJson returns whole body without requiring data', () async {
      final body = {
        'summary': {'active_projects': 2},
        'projects': [],
      };
      final client =
          clientThatResponds((_) async => http.Response(jsonEncode(body), 200));

      expect(await client.getJson('/api/est/projects'), body);
    });

    test('getJson does not fail on status field', () async {
      final client = clientThatResponds(
        (_) async =>
            http.Response(jsonEncode({'status': false, 'data': {}}), 200),
      );

      expect(
        await client.getJson('/api/est/projects'),
        {'status': false, 'data': {}},
      );
    });

    test('getJson appends query', () async {
      late http.Request seen;
      final client = clientThatResponds((request) async {
        seen = request;
        return http.Response('{}', 200);
      });

      await client.getJson(
        '/api/est/resources/mandors',
        query: {'search': 'budi'},
      );

      expect(seen.method, 'GET');
      expect(seen.url.path, '/api/est/resources/mandors');
      expect(seen.url.queryParameters, {'search': 'budi'});
    });

    test('putJson sends PUT with JSON body', () async {
      late http.Request seen;
      final client = clientThatResponds((request) async {
        seen = request;
        return http.Response('{"ok":true}', 200);
      });

      final result = await client.putJson('/api/est/x', body: {'name': 'A'});

      expect(seen.method, 'PUT');
      expect(jsonDecode(seen.body), {'name': 'A'});
      expect(result, {'ok': true});
    });

    test('postJson 422 throws badRequest with first validation error',
        () async {
      final client = clientThatResponds(
        (_) async => http.Response(
          jsonEncode({
            'message': 'x',
            'errors': {
              'name': ['Nama wajib diisi.'],
            },
          }),
          422,
        ),
      );

      expect(
        () => client.postJson('/api/est/x', body: {}),
        throwsA(
          isA<ApiException>()
              .having((e) => e.kind, 'kind', ApiErrorKind.badRequest)
              .having((e) => e.message, 'message', 'Nama wajib diisi.'),
        ),
      );
    });

    test('getJson 403 throws unauthorized', () async {
      final client = clientThatResponds((_) async => http.Response('{}', 403));

      expect(
        () => client.getJson('/api/est/x'),
        throwsA(
          isA<ApiException>()
              .having((e) => e.kind, 'kind', ApiErrorKind.unauthorized),
        ),
      );
    });

    test('deleteJson 204 empty body returns {}', () async {
      late http.Request seen;
      final client = clientThatResponds((request) async {
        seen = request;
        return http.Response('', 204);
      });

      expect(await client.deleteJson('/api/est/x/1'), isEmpty);
      expect(seen.method, 'DELETE');
    });

    test('postJson 200 non-JSON body returns {}', () async {
      final client = clientThatResponds(
          (_) async => http.Response('<html>ok</html>', 200));

      expect(await client.postJson('/api/est/x'), isEmpty);
    });

    test('postMultipartJson sends fields and photos[]', () async {
      final dir = await Directory.systemTemp.createTemp('raw_json_test');
      addTearDown(() => dir.delete(recursive: true));
      final photo = File('${dir.path}/a.jpg')..writeAsBytesSync([1, 2, 3]);

      final sent = <http.BaseRequest>[];
      final bodies = <String>[];
      final mock = MockClient.streaming((request, bodyStream) async {
        sent.add(request);
        bodies
            .add(utf8.decode(await bodyStream.toBytes(), allowMalformed: true));
        return http.StreamedResponse(
            Stream.value(utf8.encode('{"id":1}')), 200);
      });
      final client = ApiClient(httpClient: mock);

      final result = await client.postMultipartJson(
        '/api/est/attendance',
        fields: {'auto_clock_out': '1'},
        files: {
          'photos[]': [photo.path],
        },
      );

      expect(result, {'id': 1});
      expect(sent.single.headers['content-type'],
          startsWith('multipart/form-data'));
      expect(bodies.single, contains('name="photos[]"'));
      expect(bodies.single, contains('name="auto_clock_out"'));
    });
  });
}
