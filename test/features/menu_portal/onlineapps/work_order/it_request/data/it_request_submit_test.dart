import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:hris_mobile/core/network/api_client.dart';
import 'package:hris_mobile/core/network/api_exception.dart';
import 'package:hris_mobile/features/menu_portal/onlineapps/work_order/it_request/data/it_request_repository.dart';
import 'package:hris_mobile/features/menu_portal/onlineapps/work_order/it_request/domain/it_request_type.dart';
import 'package:hris_mobile/features/menu_portal/onlineapps/work_order/it_request/domain/support_type.dart';

import '../../../../../../fixtures/it_request_response.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('it_request_submit_test');
  });

  tearDown(() async {
    if (tempDir.existsSync()) await tempDir.delete(recursive: true);
  });

  ({ItRequestRepository repository, List<http.BaseRequest> sent, List<String> bodies})
      build({int statusCode = 201, Map<String, dynamic>? responseBody}) {
    final sent = <http.BaseRequest>[];
    final bodies = <String>[];

    final mock = MockClient.streaming((request, bodyStream) async {
      sent.add(request);
      bodies.add(utf8.decode(await bodyStream.toBytes()));
      return http.StreamedResponse(
        Stream.value(
          utf8.encode(jsonEncode(
            responseBody ?? {'message': 'IT request berhasil diajukan.', 'data': itRequestDetail()},
          )),
        ),
        statusCode,
      );
    });

    return (
      repository: ItRequestRepository(apiClient: ApiClient(httpClient: mock)),
      sent: sent,
      bodies: bodies,
    );
  }

  test('mengirim POST ke path yang benar', () async {
    final h = build();

    await h.repository.submit(
      type: ItRequestType.it,
      supportType: SupportType.request,
      requestCategoryCode: 'internet_req',
      description: 'Mohon dibuka akses VPN',
    );

    expect(h.sent.single.method, 'POST');
    expect(h.sent.single.url.path, '/api/portal/apps/it_request');
  });

  test('mengirim field umum yang wajib', () async {
    final h = build();

    await h.repository.submit(
      type: ItRequestType.media,
      supportType: SupportType.request,
      requestCategoryCode: 'printing_req',
      description: 'Cetak banner 3x1 meter',
    );

    final body = h.bodies.single;
    expect(body, contains('name="type_request"'));
    expect(body, contains('2'));
    expect(body, contains('name="jenis_dukungan"'));
    expect(body, contains('PERMINTAAN'));
    expect(body, contains('name="request_category"'));
    expect(body, contains('printing_req'));
    expect(body, contains('name="deskripsi"'));
    expect(body, contains('Cetak banner 3x1 meter'));
  });

  test('field tambahan per kategori ikut terkirim', () async {
    final h = build();

    await h.repository.submit(
      type: ItRequestType.it,
      supportType: SupportType.repair,
      requestCategoryCode: 'perangkat_komputer_req',
      description: 'Laptop layar berkedip sejak pagi, mouse juga tidak terdeteksi',
      categoryFields: const {
        'hardware_need_laptop': '1',
        'hardware_need_mouse': '1',
      },
    );

    final body = h.bodies.single;
    expect(body, contains('name="hardware_need_laptop"'));
    expect(body, contains('name="hardware_need_mouse"'));
  });

  test('lampiran gambar terkirim dengan nama field "image"', () async {
    final h = build();
    final photo = File('${tempDir.path}/foto.jpg');
    await photo.writeAsBytes([1, 2, 3, 4]);

    await h.repository.submit(
      type: ItRequestType.it,
      supportType: SupportType.repair,
      requestCategoryCode: 'perangkat_komputer_req',
      description: 'Laptop layar berkedip',
      categoryFields: const {'hardware_need_laptop': '1'},
      imagePath: photo.path,
    );

    final body = h.bodies.single;
    expect(body, contains('name="image"'));
    expect(body, contains('filename="foto.jpg"'));
  });

  test('tanpa imagePath, tidak ada bagian file yang terkirim', () async {
    final h = build();

    await h.repository.submit(
      type: ItRequestType.it,
      supportType: SupportType.request,
      requestCategoryCode: 'internet_req',
      description: 'Mohon dibuka akses VPN',
    );

    expect(h.bodies.single, isNot(contains('name="image"')));
  });

  test('memetakan respons 201 lewat ItRequestDetail — bentuknya sama '
      'dengan GET detail', () async {
    final h = build(
      responseBody: {
        'message': 'IT request berhasil diajukan.',
        'data': itRequestDetail(id: 2426, statusCode: 'waiting', statusLabel: 'On Waiting', rating: null),
      },
    );

    final detail = await h.repository.submit(
      type: ItRequestType.it,
      supportType: SupportType.request,
      requestCategoryCode: 'internet_req',
      description: 'Mohon dibuka akses VPN',
    );

    expect(detail.id, 2426);
    expect(detail.status.code, 'waiting');
    expect(detail.requester, isNotNull);
  });

  test('meneruskan galat validasi sebagai ApiException', () async {
    final h = build(
      statusCode: 422,
      responseBody: {
        'message': 'The type request field is required. (and 3 more errors)',
        'errors': {
          'type_request': ['The type request field is required.'],
        },
      },
    );

    expect(
      () => h.repository.submit(
        type: ItRequestType.it,
        supportType: SupportType.request,
        requestCategoryCode: 'internet_req',
        description: 'Mohon dibuka akses VPN',
      ),
      throwsA(
        isA<ApiException>().having(
          (e) => e.message,
          'message',
          'The type request field is required.',
        ),
      ),
    );
  });
}
