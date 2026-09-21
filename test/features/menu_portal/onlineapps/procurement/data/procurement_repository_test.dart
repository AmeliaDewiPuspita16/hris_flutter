import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:hris_mobile/core/network/api_client.dart';
import 'package:hris_mobile/core/network/api_exception.dart';
import 'package:hris_mobile/features/menu_portal/onlineapps/procurement/data/procurement_repository.dart';

import '../../../../../fixtures/eprocurement_response.dart';

void main() {
  ({ProcurementRepository repository, List<Uri> requested}) build({
    Map<String, dynamic>? body,
    int statusCode = 200,
  }) {
    final requested = <Uri>[];
    final client = ApiClient(
      httpClient: MockClient((request) async {
        requested.add(request.url);
        return http.Response(
          jsonEncode(body ?? eprocurementListEnvelope()),
          statusCode,
        );
      }),
    );

    return (
      repository: ProcurementRepository(apiClient: client),
      requested: requested,
    );
  }

  group('fetchList', () {
    test('meminta halaman dan jumlah baris yang diminta', () async {
      final h = build();

      await h.repository.fetchList(page: 3, perPage: 20);

      expect(h.requested.single.path, '/api/portal/apps/eprocurement');
      expect(h.requested.single.queryParameters, {
        'page': '3',
        'per_page': '20',
      });
    });

    test('menyertakan status dan kata kunci pencarian', () async {
      final h = build();

      await h.repository.fetchList(statusCode: 'pending_hod', search: 'forklift');

      expect(h.requested.single.queryParameters['status'], 'pending_hod');
      expect(h.requested.single.queryParameters['search'], 'forklift');
    });

    test('meng-encode kata kunci yang mengandung spasi dan simbol', () async {
      final h = build();

      await h.repository.fetchList(search: 'PR/HSE & oli');

      expect(h.requested.single.queryParameters['search'], 'PR/HSE & oli');
    });

    test('tidak mengirim status maupun search saat keduanya kosong', () async {
      final h = build();

      await h.repository.fetchList(statusCode: null, search: '   ');

      expect(h.requested.single.queryParameters.containsKey('status'), isFalse);
      expect(h.requested.single.queryParameters.containsKey('search'), isFalse);
    });

    test('memetakan daftar, ringkasan, dan paginasi dari satu amplop', () async {
      final h = build(
        body: eprocurementListEnvelope(currentPage: 2, lastPage: 5),
      );

      final page = await h.repository.fetchList(page: 2);

      expect(page.items.single.prNumber, 'PR/AML/26-09/01');
      expect(page.summary.all, 9);
      expect(page.meta.hasMore, isTrue);
    });

    test('meneruskan kegagalan server sebagai ApiException', () async {
      final h = build(body: const {'message': 'Server sibuk'}, statusCode: 500);

      expect(
        () => h.repository.fetchList(),
        throwsA(isA<ApiException>()),
      );
    });
  });

  group('fetchDetail', () {
    test('meminta endpoint detail dengan id PR', () async {
      final h = build(body: {'data': eprocurementDetail()});

      await h.repository.fetchDetail(3);

      expect(h.requested.single.path, '/api/portal/apps/eprocurement/3');
    });

    test('memetakan respons detail lengkap dengan item dan lampiran', () async {
      final h = build(body: {'data': eprocurementDetail()});

      final pr = await h.repository.fetchDetail(3);

      expect(pr.prNumber, 'PR/HSE/26-08/01');
      expect(pr.items, hasLength(2));
      expect(pr.attachments, hasLength(1));
      expect(pr.approvalProgress, hasLength(3));
    });

    test('respons yang tidak bisa dipetakan jadi ApiException, bukan crash',
        () async {
      final h = build(body: const {
        'data': {'pr_number': 'PR/HSE/26-08/01'},
      });

      expect(
        () => h.repository.fetchDetail(3),
        throwsA(
          isA<ApiException>()
              .having((e) => e.kind, 'kind', ApiErrorKind.server),
        ),
      );
    });
  });
}
