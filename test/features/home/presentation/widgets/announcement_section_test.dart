import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hris_mobile/features/home/domain/published_announcement.dart';
import 'package:hris_mobile/features/home/presentation/widgets/announcement_section.dart';

import '../../../../fixtures/announcement_list_response.dart';

void main() {
  PublishedAnnouncement item({
    int id = 1,
    String title = 'Payroll cut-off',
    String? body = 'Isi pengumuman',
    List<Map<String, dynamic>>? photos,
  }) {
    return PublishedAnnouncement.fromJson(
      announcementListItem(id: id, title: title, body: body, photos: photos),
    );
  }

  List<Map<String, dynamic>> photoRefs(int count) => [
        for (var i = 0; i < count; i++)
          {'id': i + 1, 'url': 'https://biieportal.co.id/storage/p$i.jpg'},
      ];

  Future<void> pumpSection(
    WidgetTester tester, {
    List<PublishedAnnouncement> announcements = const [],
    bool isLoading = false,
    String? errorMessage,
    VoidCallback? onRetry,
    bool canCreate = true,
    ValueChanged<PublishedAnnouncement>? onTapAnnouncement,
  }) {
    return tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: AnnouncementSection(
              announcements: announcements,
              isLoading: isLoading,
              errorMessage: errorMessage,
              onRetry: onRetry,
              canCreate: canCreate,
              onTapAnnouncement: onTapAnnouncement,
            ),
          ),
        ),
      ),
    );
  }

  group('keadaan', () {
    testWidgets('menampilkan indikator selagi memuat', (tester) async {
      await pumpSection(tester, isLoading: true);

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('No announcements yet'), findsNothing);
    });

    testWidgets('menampilkan pesan galat beserta tombol coba lagi',
        (tester) async {
      await pumpSection(
        tester,
        errorMessage: 'Tidak ada koneksi internet.',
        onRetry: () {},
      );

      expect(find.text('Tidak ada koneksi internet.'), findsOneWidget);
      expect(find.text('Coba lagi'), findsOneWidget);
    });

    testWidgets('tombol coba lagi memanggil onRetry', (tester) async {
      var retries = 0;
      await pumpSection(
        tester,
        errorMessage: 'Gagal memuat.',
        onRetry: () => retries++,
      );

      await tester.tap(find.text('Coba lagi'));
      await tester.pump();

      expect(retries, 1);
    });

    testWidgets('menampilkan keadaan kosong saat server tidak punya data',
        (tester) async {
      await pumpSection(tester);

      expect(find.text('No announcements yet'), findsOneWidget);
    });

    testWidgets('menyembunyikan seluruh bagian saat kosong dan tidak berizin',
        (tester) async {
      await pumpSection(tester, canCreate: false);

      expect(find.text('Announcements'), findsNothing);
    });

    testWidgets('tetap menampilkan bagian saat galat walau tidak berizin',
        (tester) async {
      await pumpSection(
        tester,
        canCreate: false,
        errorMessage: 'Gagal memuat.',
        onRetry: () {},
      );

      expect(find.text('Announcements'), findsOneWidget);
    });
  });

  group('daftar', () {
    testWidgets('menampilkan judul, isi, dan departemen', (tester) async {
      await pumpSection(tester, announcements: [item()]);

      expect(find.text('Payroll cut-off'), findsOneWidget);
      expect(find.text('Isi pengumuman'), findsOneWidget);
      expect(find.text('HR & GA'), findsOneWidget);
    });

    testWidgets('menampilkan waktu relatif, bukan tanggal penuh',
        (tester) async {
      await pumpSection(
        tester,
        announcements: [
          PublishedAnnouncement.fromJson(
            announcementListItem(
              createdAt: DateTime.now()
                  .subtract(const Duration(hours: 2))
                  .toIso8601String(),
            ),
          ),
        ],
      );

      expect(find.text('2h ago'), findsOneWidget);
    });

    testWidgets('meneruskan pengumuman yang diketuk', (tester) async {
      PublishedAnnouncement? tapped;
      await pumpSection(
        tester,
        announcements: [item(id: 7, title: 'Yang diketuk')],
        onTapAnnouncement: (a) => tapped = a,
      );

      await tester.tap(find.text('Yang diketuk'));
      await tester.pump();

      expect(tapped, isNotNull);
      expect(tapped!.id, 7);
    });
  });

  group('thumbnail foto', () {
    testWidgets('tidak menampilkan apa pun saat pengumuman tanpa foto',
        (tester) async {
      await pumpSection(tester, announcements: [item(photos: [])]);

      expect(find.byType(Image), findsNothing);
    });

    testWidgets('menampilkan satu thumbnail untuk satu foto', (tester) async {
      await pumpSection(tester, announcements: [item(photos: photoRefs(1))]);

      expect(find.byType(Image), findsOneWidget);
    });

    testWidgets('menampilkan paling banyak tiga thumbnail', (tester) async {
      await pumpSection(tester, announcements: [item(photos: photoRefs(5))]);

      expect(find.byType(Image), findsNWidgets(3));
    });

    testWidgets('menandai sisa foto yang tidak muat', (tester) async {
      await pumpSection(tester, announcements: [item(photos: photoRefs(5))]);

      expect(find.text('+2'), findsOneWidget);
    });

    testWidgets('tidak menandai sisa saat semua foto terlihat',
        (tester) async {
      // canCreate dimatikan supaya tombol "+ New" di header tidak ikut
      // tertangkap pencarian teks berawalan "+".
      await pumpSection(
        tester,
        canCreate: false,
        announcements: [item(photos: photoRefs(3))],
      );

      expect(find.textContaining('+'), findsNothing);
    });

    testWidgets('melewati foto yang URL-nya tidak bisa dipakai',
        (tester) async {
      await pumpSection(
        tester,
        announcements: [
          item(
            photos: [
              {'id': 1, 'url': 'bukan url'},
              {'id': 2, 'url': 'https://biieportal.co.id/storage/b.jpg'},
            ],
          ),
        ],
      );

      expect(find.byType(Image), findsOneWidget);
    });
  });
}
