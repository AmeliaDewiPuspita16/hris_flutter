import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:hris_mobile/core/network/api_client.dart';
import 'package:hris_mobile/core/network/api_exception.dart';
import 'package:hris_mobile/features/menu_portal/onlineapps/work_order/it_request/data/it_request_repository.dart';

import '../../../../../../fixtures/it_request_response.dart';

void main() {
  late Directory tempDir;
  late File photo;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('it_request_complete_test');
    photo = File('${tempDir.path}/done.jpg');
    await photo.writeAsBytes([1, 2, 3, 4]);
  });

  tearDown(() async {
    if (tempDir.existsSync()) await tempDir.delete(recursive: true);
  });

  ({ItRequestRepository repository, List<http.BaseRequest> sent, List<String> bodies})
      build({int statusCode = 200, Map<String, dynamic>? responseBody}) {
    final sent = <http.BaseRequest>[];
    final bodies = <String>[];

    final mock = MockClient.streaming((request, bodyStream) async {
      sent.add(request);
      bodies.add(utf8.decode(await bodyStream.toBytes()));
      return http.StreamedResponse(
        Stream.value(utf8.encode(jsonEncode(
          responseBody ??
              {
                'message': 'Request marked as completed.',
                'data': itRequestDetail(
                  id: 123,
                  statusCode: 'wait_checked',
                  statusLabel: 'Wait Checked',
                ),
              },
        ))),
        statusCode,
      );
    });

    return (
      repository: ItRequestRepository(apiClient: ApiClient(httpClient: mock)),
      sent: sent,
      bodies: bodies,
    );
  }

  test('mengirim POST multipart ke endpoint complete dengan id request', () async {
    final h = build();

    await h.repository.complete(123, photoPath: photo.path);

    expect(h.sent.single.method, 'POST');
    expect(h.sent.single.url.path, '/api/portal/apps/it_request/123/complete');
  });

  test('foto terkirim dengan nama field "photo"', () async {
    final h = build();

    await h.repository.complete(123, photoPath: photo.path);

    expect(h.bodies.single, contains('name="photo"'));
    expect(h.bodies.single, contains('filename="done.jpg"'));
  });

  test('note opsional ikut terkirim bila diisi', () async {
    final h = build();

    await h.repository.complete(123, photoPath: photo.path, note: 'Wifi installed and tested.');

    expect(h.bodies.single, contains('name="note"'));
    expect(h.bodies.single, contains('Wifi installed and tested.'));
  });

  test('tanpa note, tidak ada bagian note yang terkirim', () async {
    final h = build();

    await h.repository.complete(123, photoPath: photo.path);

    expect(h.bodies.single, isNot(contains('name="note"')));
  });

  test('memetakan rincian terbaru (status berubah jadi wait_checked)', () async {
    final h = build();

    final detail = await h.repository.complete(123, photoPath: photo.path);

    expect(detail.id, 123);
    expect(detail.status.code, 'wait_checked');
  });

  test('meneruskan galat validasi (foto tidak disertakan) sebagai ApiException', () async {
    final h = build(
      statusCode: 422,
      responseBody: const {
        'message': 'The photo field is required.',
        'errors': {
          'photo': ['Please attach a photo as evidence.'],
        },
      },
    );

    expect(
      () => h.repository.complete(123, photoPath: photo.path),
      throwsA(isA<ApiException>()),
    );
  });
}
