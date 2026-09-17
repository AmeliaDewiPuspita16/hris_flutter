import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:hris_mobile/core/network/api_client.dart';
import 'package:hris_mobile/core/network/api_exception.dart';
import 'package:hris_mobile/features/home/data/announcement_repository.dart';
import 'package:hris_mobile/features/home/domain/announcement_photo.dart';

import '../../../fixtures/published_announcement_response.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('announcement_test');
  });

  tearDown(() async {
    if (tempDir.existsSync()) await tempDir.delete(recursive: true);
  });

  Future<AnnouncementPhoto> writePhoto(
    String name, {
    int sizeBytes = 64,
  }) async {
    final file = File('${tempDir.path}/$name');
    await file.writeAsBytes(List.filled(sizeBytes, 7));
    return AnnouncementPhoto(
      path: file.path,
      fileName: name,
      sizeBytes: sizeBytes,
    );
  }

  ({AnnouncementRepository repository, List<String> bodies, List<int> calls})
      build({int statusCode = 201, String? responseBody}) {
    final bodies = <String>[];
    final calls = <int>[];

    final mock = MockClient.streaming((request, bodyStream) async {
      calls.add(1);
      bodies.add(utf8.decode(await bodyStream.toBytes()));
      return http.StreamedResponse(
        Stream.value(
          utf8.encode(
            responseBody ?? jsonEncode(publishAnnouncementEnvelope()),
          ),
        ),
        statusCode,
      );
    });

    return (
      repository: AnnouncementRepository(
        apiClient: ApiClient(httpClient: mock),
      ),
      bodies: bodies,
      calls: calls,
    );
  }

  group('publish', () {
    test('mengirim department_id, title, dan body sebagai field', () async {
      final built = build();

      await built.repository.publish(
        departmentId: 8,
        title: 'Payroll cut-off pindah ke tanggal 23',
        body: 'Klaim lembur disetujui HOD sebelum 23 Sep, 17:00.',
      );

      final sent = built.bodies.single;
      expect(sent, contains('name="department_id"'));
      expect(sent, contains('8'));
      expect(sent, contains('name="title"'));
      expect(sent, contains('Payroll cut-off pindah ke tanggal 23'));
      expect(sent, contains('name="body"'));
    });

    test('tidak mengirim field body saat isinya kosong', () async {
      final built = build();

      await built.repository.publish(
        departmentId: 8,
        title: 'Judul saja',
        body: '   ',
      );

      expect(built.bodies.single, isNot(contains('name="body"')));
    });

    test('mengirim foto di bawah nama field photos[]', () async {
      final built = build();
      final poster = await writePhoto('poster1.jpg');

      await built.repository.publish(
        departmentId: 8,
        title: 'Dengan lampiran',
        photos: [poster],
      );

      expect(built.bodies.single, contains('name="photos[]"'));
      expect(built.bodies.single, contains('filename="poster1.jpg"'));
    });

    test('mengembalikan pengumuman hasil parsing respons', () async {
      final built = build();

      final published = await built.repository.publish(
        departmentId: 8,
        title: 'Payroll cut-off pindah ke tanggal 23',
      );

      expect(published.id, 1);
      expect(published.department.name, 'HR & GA');
      expect(published.photos, hasLength(2));
    });
  });

  group('pemeriksaan foto sebelum diunggah', () {
    test('menolak lebih dari 10 foto tanpa menghubungi server', () async {
      final built = build();
      final photos = <AnnouncementPhoto>[];
      for (var i = 0; i < 11; i++) {
        photos.add(await writePhoto('poster$i.jpg'));
      }

      await expectLater(
        built.repository.publish(
          departmentId: 8,
          title: 'Terlalu banyak',
          photos: photos,
        ),
        throwsA(
          isA<ApiException>().having((e) => e.message, 'pesan', contains('10')),
        ),
      );
      expect(built.calls, isEmpty);
    });

    test('menolak format selain JPG dan PNG tanpa menghubungi server',
        () async {
      final built = build();
      final berkas = await writePhoto('dokumen.pdf');

      await expectLater(
        built.repository.publish(
          departmentId: 8,
          title: 'Format salah',
          photos: [berkas],
        ),
        throwsA(
          isA<ApiException>()
              .having((e) => e.message, 'pesan', contains('dokumen.pdf')),
        ),
      );
      expect(built.calls, isEmpty);
    });

    test('menolak foto lebih dari 5 MB tanpa menghubungi server', () async {
      final built = build();
      final besar = AnnouncementPhoto(
        path: '${tempDir.path}/besar.jpg',
        fileName: 'besar.jpg',
        sizeBytes: AnnouncementPhoto.maxSizeBytes + 1,
      );

      await expectLater(
        built.repository.publish(
          departmentId: 8,
          title: 'Kebesaran',
          photos: [besar],
        ),
        throwsA(
          isA<ApiException>().having((e) => e.message, 'pesan', contains('5 MB')),
        ),
      );
      expect(built.calls, isEmpty);
    });
  });

  group('kegagalan dari server', () {
    test('meneruskan pesan validasi 422', () async {
      final built = build(
        statusCode: 422,
        responseBody: jsonEncode({
          'message': 'The given data was invalid.',
          'errors': {
            'department_id': ['The selected department id is invalid.'],
          },
        }),
      );

      await expectLater(
        built.repository.publish(departmentId: 999, title: 'Dept nonaktif'),
        throwsA(
          isA<ApiException>()
              .having((e) => e.kind, 'kind', ApiErrorKind.badRequest)
              .having(
                (e) => e.message,
                'pesan',
                'The selected department id is invalid.',
              ),
        ),
      );
    });

    test('meneruskan penolakan izin 403', () async {
      final built = build(
        statusCode: 403,
        responseBody: jsonEncode({'message': 'This action is unauthorized.'}),
      );

      await expectLater(
        built.repository.publish(departmentId: 8, title: 'Tanpa izin'),
        throwsA(
          isA<ApiException>()
              .having((e) => e.kind, 'kind', ApiErrorKind.unauthorized),
        ),
      );
    });

    test('mengubah respons sukses yang cacat jadi galat server', () async {
      final built = build(
        responseBody: jsonEncode({
          'message': 'Pengumuman berhasil diterbitkan.',
          'data': {'title': 'tanpa id'},
        }),
      );

      await expectLater(
        built.repository.publish(departmentId: 8, title: 'Cacat'),
        throwsA(
          isA<ApiException>()
              .having((e) => e.kind, 'kind', ApiErrorKind.server),
        ),
      );
    });
  });
}
