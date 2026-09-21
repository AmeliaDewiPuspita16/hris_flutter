import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:hris_mobile/core/network/api_client.dart';
import 'package:hris_mobile/core/network/api_exception.dart';
import 'package:hris_mobile/features/menu_portal/onlineapps/work_order/it_request/data/it_request_repository.dart';

import '../../../../../../fixtures/it_request_response.dart';

void main() {
  ({ItRequestRepository repository, List<Uri> requested}) build({
    Map<String, dynamic>? body,
    int statusCode = 200,
  }) {
    final requested = <Uri>[];
    final client = ApiClient(
      httpClient: MockClient((request) async {
        requested.add(request.url);
        return http.Response(jsonEncode(body ?? itRequestListEnvelope()), statusCode);
      }),
    );

    return (repository: ItRequestRepository(apiClient: client), requested: requested);
  }

  group('fetchList', () {
    test('meminta halaman dan jumlah baris yang diminta', () async {
      final h = build();

      await h.repository.fetchList(page: 3, perPage: 20);

      expect(h.requested.single.path, '/api/portal/apps/it_request');
      expect(h.requested.single.queryParameters, {'page': '3', 'per_page': '20'});
    });

    test('memetakan daftar, ringkasan, dan paginasi dari satu amplop', () async {
      final h = build(body: itRequestListEnvelope(awaitingRating: 6, lastPage: 57));

      final page = await h.repository.fetchList(page: 1);

      expect(page.items.single.id, 2395);
      expect(page.summary.awaitingRating, 6);
      expect(page.meta.hasMore, isTrue);
    });

    test('meneruskan kegagalan server sebagai ApiException', () async {
      final h = build(body: const {'message': 'Server sibuk'}, statusCode: 500);

      expect(() => h.repository.fetchList(), throwsA(isA<ApiException>()));
    });
  });

  group('fetchDetail', () {
    test('meminta endpoint detail dengan id request', () async {
      final h = build(body: {'data': itRequestDetail()});

      await h.repository.fetchDetail(2395);

      expect(h.requested.single.path, '/api/portal/apps/it_request/2395');
    });

    test('memetakan respons detail lengkap', () async {
      final h = build(body: {'data': itRequestDetail()});

      final detail = await h.repository.fetchDetail(2395);

      expect(detail.id, 2395);
      expect(detail.requester?.name, 'Frida Khaerani');
      expect(detail.handling?.workBy, 'Aditya Yudha Pratama');
    });

    test('respons yang tidak bisa dipetakan jadi ApiException, bukan crash',
        () async {
      final h = build(body: const {
        'data': {'description': 'tanpa id'},
      });

      expect(
        () => h.repository.fetchDetail(2395),
        throwsA(
          isA<ApiException>().having((e) => e.kind, 'kind', ApiErrorKind.server),
        ),
      );
    });
  });
}
