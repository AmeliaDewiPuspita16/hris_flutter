import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:hris_mobile/core/network/api_client.dart';
import 'package:hris_mobile/core/network/api_exception.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('multipart_test');
  });

  tearDown(() async {
    if (tempDir.existsSync()) await tempDir.delete(recursive: true);
  });

  /// Berkas sungguhan di disk — MultipartFile membacanya lewat path.
  Future<File> writeFile(String name, List<int> bytes) async {
    final file = File('${tempDir.path}/$name');
    await file.writeAsBytes(bytes);
    return file;
  }

  /// MockClient hanya menerima http.Request, sementara multipart mengirim
  /// StreamedRequest — jadi badannya ditangkap lewat MockClient.streaming.
  ({ApiClient client, List<http.BaseRequest> sent, List<String> bodies})
      clientThatCaptures({int statusCode = 201, String? responseBody}) {
    final sent = <http.BaseRequest>[];
    final bodies = <String>[];

    final mock = MockClient.streaming((request, bodyStream) async {
      sent.add(request);
      bodies.add(utf8.decode(await bodyStream.toBytes()));
      return http.StreamedResponse(
        Stream.value(
          utf8.encode(
            responseBody ??
                jsonEncode({
                  'message': 'Pengumuman berhasil diterbitkan.',
                  'data': {'id': 1, 'title': 'Judul'},
                }),
          ),
        ),
        statusCode,
      );
    });

    return (client: ApiClient(httpClient: mock), sent: sent, bodies: bodies);
  }

  test('mengirim sebagai POST multipart/form-data', () async {
    final captured = clientThatCaptures();

    await captured.client.postMultipart('/api/portal/hr_announcement');

    expect(captured.sent.single.method, 'POST');
    expect(
      captured.sent.single.headers['content-type'],
      contains('multipart/form-data'),
    );
  });

  test('menyusun URL dari base URL dan path', () async {
    final captured = clientThatCaptures();

    await captured.client.postMultipart('/api/portal/hr_announcement');

    expect(captured.sent.single.url.path, '/api/portal/hr_announcement');
  });

  test('mengirim field teks sebagai bagian form', () async {
    final captured = clientThatCaptures();

    await captured.client.postMultipart(
      '/api/portal/hr_announcement',
      fields: {'department_id': '8', 'title': 'Payroll cut-off'},
    );

    expect(captured.bodies.single, contains('name="department_id"'));
    expect(captured.bodies.single, contains('8'));
    expect(captured.bodies.single, contains('name="title"'));
    expect(captured.bodies.single, contains('Payroll cut-off'));
  });

  test('mengirim berkas dengan nama field dan nama berkas yang benar',
      () async {
    final captured = clientThatCaptures();
    final poster = await writeFile('poster1.jpg', [1, 2, 3, 4]);

    await captured.client.postMultipart(
      '/api/portal/hr_announcement',
      files: {'photos[]': [poster.path]},
    );

    expect(captured.bodies.single, contains('name="photos[]"'));
    expect(captured.bodies.single, contains('filename="poster1.jpg"'));
  });

  test('mengirim beberapa berkas di bawah nama field yang sama', () async {
    final captured = clientThatCaptures();
    final first = await writeFile('poster1.jpg', [1, 2, 3]);
    final second = await writeFile('poster2.png', [4, 5, 6]);

    await captured.client.postMultipart(
      '/api/portal/hr_announcement',
      files: {
        'photos[]': [first.path, second.path],
      },
    );

    expect(captured.bodies.single, contains('filename="poster1.jpg"'));
    expect(captured.bodies.single, contains('filename="poster2.png"'));
  });

  test('memasang header Authorization saat token sudah diset', () async {
    final captured = clientThatCaptures();
    captured.client.setToken('9999|token-palsu');

    await captured.client.postMultipart('/api/portal/hr_announcement');

    expect(
      captured.sent.single.headers['Authorization'],
      'Bearer 9999|token-palsu',
    );
  });

  test('mengembalikan isi data dari amplop respons', () async {
    final captured = clientThatCaptures(
      responseBody: jsonEncode({
        'message': 'Pengumuman berhasil diterbitkan.',
        'data': {'id': 7, 'title': 'Judul'},
      }),
    );

    final data = await captured.client.postMultipart(
      '/api/portal/hr_announcement',
    );

    expect(data['id'], 7);
    expect(data['title'], 'Judul');
  });

  test('meneruskan pesan validasi 422 dari server', () async {
    final captured = clientThatCaptures(
      statusCode: 422,
      responseBody: jsonEncode({
        'message': 'The given data was invalid.',
        'errors': {
          'title': ['The title must not be greater than 200 characters.'],
        },
      }),
    );

    await expectLater(
      captured.client.postMultipart('/api/portal/hr_announcement'),
      throwsA(
        isA<ApiException>()
            .having((e) => e.kind, 'kind', ApiErrorKind.badRequest)
            .having(
              (e) => e.message,
              'message',
              'The title must not be greater than 200 characters.',
            ),
      ),
    );
  });

  test('memetakan 403 tanpa izin ke ApiErrorKind.unauthorized', () async {
    final captured = clientThatCaptures(
      statusCode: 403,
      responseBody: jsonEncode({'message': 'This action is unauthorized.'}),
    );

    await expectLater(
      captured.client.postMultipart('/api/portal/hr_announcement'),
      throwsA(
        isA<ApiException>()
            .having((e) => e.kind, 'kind', ApiErrorKind.unauthorized)
            .having((e) => e.message, 'message', 'This action is unauthorized.'),
      ),
    );
  });

  test('menerjemahkan kegagalan jaringan jadi ApiErrorKind.network', () async {
    final client = ApiClient(
      httpClient: MockClient.streaming(
        (_, __) async => throw http.ClientException('Connection closed'),
      ),
    );

    await expectLater(
      client.postMultipart('/api/portal/hr_announcement'),
      throwsA(
        isA<ApiException>().having((e) => e.kind, 'kind', ApiErrorKind.network),
      ),
    );
  });
}
