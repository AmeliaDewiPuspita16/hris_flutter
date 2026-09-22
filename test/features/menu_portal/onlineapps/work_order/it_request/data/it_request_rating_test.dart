import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:hris_mobile/core/network/api_client.dart';
import 'package:hris_mobile/core/network/api_exception.dart';
import 'package:hris_mobile/features/menu_portal/onlineapps/work_order/it_request/data/it_request_repository.dart';

import '../../../../../../fixtures/it_request_response.dart';

void main() {
  ({ItRequestRepository repository, List<http.Request> sent})
      build({int statusCode = 200, Map<String, dynamic>? responseBody}) {
    final sent = <http.Request>[];

    final mock = MockClient((request) async {
      sent.add(request);
      return http.Response(
        jsonEncode(
          responseBody ??
              {'message': 'Rating berhasil dikirim.', 'data': itRequestDetail()},
        ),
        statusCode,
      );
    });

    return (
      repository: ItRequestRepository(apiClient: ApiClient(httpClient: mock)),
      sent: sent,
    );
  }

  test('mengirim POST ke path {id}/rating', () async {
    final h = build();

    await h.repository.submitRating(123, star: 5, message: 'Terima kasih!');

    expect(h.sent.single.method, 'POST');
    expect(h.sent.single.url.path, '/api/portal/apps/it_request/123/rating');
  });

  test('mengirim star dan message sebagai body JSON', () async {
    final h = build();

    await h.repository.submitRating(123, star: 5, message: 'Terima kasih!');

    final body = jsonDecode(h.sent.single.body) as Map<String, dynamic>;
    expect(body['star'], 5);
    expect(body['message'], 'Terima kasih!');
  });

  test('message null (catatan kosong) dikirim sebagai null', () async {
    final h = build();

    await h.repository.submitRating(123, star: 4);

    final body = jsonDecode(h.sent.single.body) as Map<String, dynamic>;
    expect(body['message'], isNull);
  });

  test('memetakan respons lewat ItRequestDetail — sama seperti GET detail',
      () async {
    final h = build(
      responseBody: {
        'message': 'Rating berhasil dikirim.',
        'data': itRequestDetail(
          id: 123,
          rating: 5,
          canRate: false,
          ratingComment: 'Responsif, masalah selesai hari yang sama.',
        ),
      },
    );

    final detail = await h.repository.submitRating(123, star: 5);

    expect(detail.id, 123);
    expect(detail.rating, 5);
    expect(detail.canRate, isFalse);
    expect(detail.ratingComment, 'Responsif, masalah selesai hari yang sama.');
  });

  test('meneruskan galat validasi sebagai ApiException', () async {
    final h = build(
      statusCode: 422,
      responseBody: {
        'message': 'The star field is required.',
        'errors': {
          'star': ['The star field is required.'],
        },
      },
    );

    expect(
      () => h.repository.submitRating(123, star: 0),
      throwsA(
        isA<ApiException>().having(
          (e) => e.message,
          'message',
          'The star field is required.',
        ),
      ),
    );
  });
}
