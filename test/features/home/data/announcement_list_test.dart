import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:hris_mobile/core/network/api_client.dart';
import 'package:hris_mobile/core/network/api_exception.dart';
import 'package:hris_mobile/features/home/data/announcement_repository.dart';

import '../../../fixtures/announcement_list_response.dart';

void main() {
  ({AnnouncementRepository repository, List<http.Request> sent}) build({
    int statusCode = 200,
    Map<String, dynamic>? body,
  }) {
    final sent = <http.Request>[];
    final client = MockClient((request) async {
      sent.add(request);
      return http.Response(
        jsonEncode(body ?? announcementListEnvelope()),
        statusCode,
      );
    });

    return (
      repository:
          AnnouncementRepository(apiClient: ApiClient(httpClient: client)),
      sent: sent,
    );
  }

  test('memanggil endpoint daftar pengumuman', () async {
    final built = build();

    await built.repository.fetchAnnouncements();

    expect(built.sent.single.method, 'GET');
    expect(built.sent.single.url.path, '/api/portal/hr_announcement');
  });

  test('mengirim page dan per_page sebagai query', () async {
    final built = build();

    await built.repository.fetchAnnouncements(page: 3, perPage: 5);

    expect(built.sent.single.url.queryParameters['page'], '3');
    expect(built.sent.single.url.queryParameters['per_page'], '5');
  });

  test('memakai halaman pertama dan 20 item sebagai bawaan', () async {
    final built = build();

    await built.repository.fetchAnnouncements();

    expect(built.sent.single.url.queryParameters['page'], '1');
    expect(built.sent.single.url.queryParameters['per_page'], '20');
  });

  test('memetakan tiap item jadi PublishedAnnouncement', () async {
    final built = build();

    final announcements = await built.repository.fetchAnnouncements();

    expect(announcements, hasLength(1));
    expect(announcements.single.id, 1);
    expect(announcements.single.title, 'Payroll cut-off pindah ke tanggal 23');
    expect(announcements.single.department.name, 'HR & GA');
    expect(announcements.single.photos, hasLength(1));
  });

  test('mempertahankan urutan dari server', () async {
    final built = build(
      body: announcementListEnvelope(
        items: [
          announcementListItem(id: 3, title: 'Paling baru'),
          announcementListItem(id: 2, title: 'Menengah'),
          announcementListItem(id: 1, title: 'Paling lama'),
        ],
      ),
    );

    final titles = (await built.repository.fetchAnnouncements())
        .map((a) => a.title)
        .toList();

    expect(titles, ['Paling baru', 'Menengah', 'Paling lama']);
  });

  test('mengembalikan daftar kosong saat belum ada pengumuman', () async {
    final built = build(body: announcementListEnvelope(items: []));

    expect(await built.repository.fetchAnnouncements(), isEmpty);
  });

  test('menerima item tanpa body maupun foto', () async {
    final built = build(
      body: announcementListEnvelope(
        items: [announcementListItem(body: null, photos: [])],
      ),
    );

    final announcement = (await built.repository.fetchAnnouncements()).single;

    expect(announcement.body, isNull);
    expect(announcement.photos, isEmpty);
  });

  test('melewati item cacat tanpa menggagalkan seluruh daftar', () async {
    final built = build(
      body: announcementListEnvelope(
        items: [
          announcementListItem(id: 1, title: 'Sehat'),
          // Tanpa id — satu baris rusak di server tidak boleh membuat
          // seluruh daftar pengumuman hilang dari layar.
          {'title': 'Cacat', 'created_at': '2026-09-16T10:30:29+07:00'},
        ],
      ),
    );

    final announcements = await built.repository.fetchAnnouncements();

    expect(announcements, hasLength(1));
    expect(announcements.single.title, 'Sehat');
  });

  test('meneruskan sesi berakhir saat token ditolak', () async {
    final built = build(
      statusCode: 401,
      body: {'message': 'Unauthenticated.'},
    );

    await expectLater(
      built.repository.fetchAnnouncements(),
      throwsA(
        isA<ApiException>()
            .having((e) => e.kind, 'kind', ApiErrorKind.unauthorized),
      ),
    );
  });

  test('meneruskan kegagalan jaringan', () async {
    final repository = AnnouncementRepository(
      apiClient: ApiClient(
        httpClient: MockClient(
          (_) async => throw http.ClientException('Connection refused'),
        ),
      ),
    );

    await expectLater(
      repository.fetchAnnouncements(),
      throwsA(
        isA<ApiException>().having((e) => e.kind, 'kind', ApiErrorKind.network),
      ),
    );
  });
}
