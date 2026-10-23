import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:hris_mobile/core/network/api_client.dart';
import 'package:hris_mobile/core/network/api_exception.dart';
import 'package:hris_mobile/features/menu_portal/onlineapps/work_order/it_request/data/it_request_repository.dart';

import '../../../../../../fixtures/it_request_response.dart';

void main() {
  ({ItRequestRepository repository, List<http.Request> sent}) build({
    int statusCode = 200,
    Map<String, dynamic>? responseBody,
  }) {
    final sent = <http.Request>[];

    final mock = MockClient((request) async {
      sent.add(request);
      return http.Response(
        jsonEncode(responseBody ??
            {
              'message': 'Request has been approved.',
              'data': itRequestDetail()
            }),
        statusCode,
      );
    });

    return (
      repository: ItRequestRepository(apiClient: ApiClient(httpClient: mock)),
      sent: sent,
    );
  }

  group('fetchApprovals', () {
    test('GET ke /approvals dengan per_page, dan ?type= bila diisi', () async {
      final h = build(responseBody: itRequestApprovalsEnvelope());

      await h.repository.fetchApprovals(type: 'Media');

      final url = h.sent.single.url;
      expect(h.sent.single.method, 'GET');
      expect(url.path, '/api/portal/apps/it_request/approvals');
      expect(url.queryParameters['per_page'], '100');
      expect(url.queryParameters['type'], 'Media');
    });

    test('memetakan requester, support type, dan summary.pending', () async {
      final h = build(responseBody: itRequestApprovalsEnvelope(pending: 2));

      final page = await h.repository.fetchApprovals();

      final item = page.items.single;
      expect(item.id, 2396);
      expect(item.requesterName, 'Rachmananda');
      expect(item.department, 'BDD');
      expect(item.description, 'Kebutuhan BD');
      expect(item.supportType, 'IT (PERMINTAAN)');
      expect(page.pending, 2);
    });

    test('Media tanpa support_type tetap berlabel "Media"', () async {
      final h = build(
        responseBody: itRequestApprovalsEnvelope(
          items: [itRequestApprovalItem(type: 'Media', supportType: null)],
        ),
      );

      final page = await h.repository.fetchApprovals();

      expect(page.items.single.supportType, 'Media');
    });

    test('baris tanpa id dilewati, sisanya tetap tampil', () async {
      final broken = itRequestApprovalItem()..remove('id');
      final h = build(
        responseBody: itRequestApprovalsEnvelope(
          items: [broken, itRequestApprovalItem(id: 7)],
        ),
      );

      final page = await h.repository.fetchApprovals();

      expect(page.items.map((i) => i.id), [7]);
    });
  });

  group('approve', () {
    test('POST ke {id}/approve', () async {
      final h = build();

      await h.repository.approve(2396);

      expect(h.sent.single.method, 'POST');
      expect(
          h.sent.single.url.path, '/api/portal/apps/it_request/2396/approve');
    });

    test('403 dilempar sebagai ApiException', () async {
      final h = build(statusCode: 403, responseBody: {'message': 'Forbidden'});

      expect(() => h.repository.approve(2396), throwsA(isA<ApiException>()));
    });
  });

  group('reject', () {
    test('POST ke {id}/reject dengan reason', () async {
      final h = build(responseBody: {
        'message': 'Request has been rejected.',
        'data': itRequestDetail(),
      });

      await h.repository.reject(2396, reason: '  Bukan prioritas  ');

      expect(h.sent.single.url.path, '/api/portal/apps/it_request/2396/reject');
      final body = jsonDecode(h.sent.single.body) as Map<String, dynamic>;
      expect(body['reason'], 'Bukan prioritas');
    });

    test('reason kosong tidak dikirim', () async {
      final h = build();

      await h.repository.reject(2396, reason: '   ');

      final body = jsonDecode(h.sent.single.body) as Map<String, dynamic>;
      expect(body.containsKey('reason'), isFalse);
    });
  });
}
