import 'package:flutter_test/flutter_test.dart';
import 'package:hris_mobile/features/home/domain/published_announcement.dart';

import '../../../fixtures/published_announcement_response.dart';

void main() {
  group('PublishedAnnouncement.fromJson', () {
    test('memetakan field dari respons yang didokumentasikan', () {
      final announcement =
          PublishedAnnouncement.fromJson(publishAnnouncementData());

      expect(announcement.id, 1);
      expect(announcement.title, 'Payroll cut-off pindah ke tanggal 23');
      expect(
        announcement.body,
        'Klaim lembur disetujui HOD sebelum 23 Sep, 17:00.',
      );
      expect(announcement.department.id, 8);
      expect(announcement.department.name, 'HR & GA');
      expect(announcement.postedByName, 'Budi Hartono Hasibuan');
    });

    test('mengurai created_at berikut zona waktunya', () {
      final announcement =
          PublishedAnnouncement.fromJson(publishAnnouncementData());

      // 10:30:29 di +07:00 sama dengan 03:30:29 UTC.
      expect(
        announcement.createdAt.toUtc(),
        DateTime.utc(2026, 9, 16, 3, 30, 29),
      );
    });

    test('memetakan daftar foto beserta URL dan nama berkasnya', () {
      final announcement =
          PublishedAnnouncement.fromJson(publishAnnouncementData());

      expect(announcement.photos, hasLength(2));
      expect(
        announcement.photos.first.url,
        'http://127.0.0.1:8000/storage/announcements/s7CY.jpg',
      );
      expect(announcement.photos.first.fileName, 'poster1.jpg');
      expect(announcement.photos.last.id, 2);
    });

    test('memberi daftar foto kosong saat pengumuman tanpa lampiran', () {
      final data = publishAnnouncementData()..remove('photos');

      expect(PublishedAnnouncement.fromJson(data).photos, isEmpty);
    });

    test('membiarkan body null saat tidak dikirim', () {
      final data = publishAnnouncementData()..remove('body');

      expect(PublishedAnnouncement.fromJson(data).body, isNull);
    });

    test('membiarkan postedByName null saat posted_by tidak dikirim', () {
      final data = publishAnnouncementData()..remove('posted_by');

      expect(PublishedAnnouncement.fromJson(data).postedByName, isNull);
    });

    test('menolak respons tanpa id', () {
      final data = publishAnnouncementData()..remove('id');

      expect(
        () => PublishedAnnouncement.fromJson(data),
        throwsA(isA<FormatException>()),
      );
    });

    test('menolak respons tanpa department', () {
      final data = publishAnnouncementData()..remove('department');

      expect(
        () => PublishedAnnouncement.fromJson(data),
        throwsA(isA<FormatException>()),
      );
    });

    test('menolak respons tanpa created_at yang bisa diurai', () {
      final data = publishAnnouncementData()..['created_at'] = 'bukan tanggal';

      expect(
        () => PublishedAnnouncement.fromJson(data),
        throwsA(isA<FormatException>()),
      );
    });
  });
}
