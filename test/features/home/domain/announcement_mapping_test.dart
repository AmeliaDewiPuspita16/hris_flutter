import 'package:flutter_test/flutter_test.dart';
import 'package:hris_mobile/features/home/domain/announcement.dart';
import 'package:hris_mobile/features/home/domain/published_announcement.dart';
import 'package:hris_mobile/features/shared/domain/department.dart';

import '../../../fixtures/published_announcement_response.dart';

void main() {
  group('AnnouncementTag.forDepartment', () {
    test('memakai nama departemen sebagai label', () {
      final tag = AnnouncementTag.forDepartment(
        const Department(id: 8, name: 'HR & GA'),
      );

      expect(tag.label, 'HR & GA');
    });

    test('memberi warna yang sama untuk departemen yang sama', () {
      const department = Department(id: 8, name: 'HR & GA');

      final first = AnnouncementTag.forDepartment(department);
      final second = AnnouncementTag.forDepartment(department);

      expect(first.color, second.color);
      expect(first.background, second.background);
    });

    test('warna ditentukan id, bukan posisi dalam daftar', () {
      // Departemen yang sama muncul di dua daftar dengan urutan berbeda —
      // warnanya harus tetap sama supaya tidak berubah-ubah antar layar.
      const hrga = Department(id: 8, name: 'HR & GA');
      const itm = Department(id: 17, name: 'ITM');

      expect(
        AnnouncementTag.forDepartment(hrga).color,
        isNot(AnnouncementTag.forDepartment(itm).color),
      );
      expect(
        AnnouncementTag.forDepartment(hrga).color,
        AnnouncementTag.forDepartment(hrga).color,
      );
    });
  });

  group('Announcement.fromPublished', () {
    test('memakai judul dan isi dari server', () {
      final published =
          PublishedAnnouncement.fromJson(publishAnnouncementData());

      final announcement = Announcement.fromPublished(published);

      expect(announcement.title, 'Payroll cut-off pindah ke tanggal 23');
      expect(
        announcement.body,
        'Klaim lembur disetujui HOD sebelum 23 Sep, 17:00.',
      );
    });

    test('memakai nama departemen sebagai label tag', () {
      final published =
          PublishedAnnouncement.fromJson(publishAnnouncementData());

      expect(Announcement.fromPublished(published).tag.label, 'HR & GA');
    });

    test('menampilkan waktu relatif terhadap sekarang', () {
      final published = PublishedAnnouncement.fromJson(
        publishAnnouncementData()
          ..['created_at'] =
              DateTime.now().subtract(const Duration(hours: 2)).toIso8601String(),
      );

      expect(Announcement.fromPublished(published).time, '2h ago');
    });

    test('membiarkan body null saat pengumuman tanpa isi', () {
      final data = publishAnnouncementData()..remove('body');

      final announcement =
          Announcement.fromPublished(PublishedAnnouncement.fromJson(data));

      expect(announcement.body, isNull);
    });
  });
}
