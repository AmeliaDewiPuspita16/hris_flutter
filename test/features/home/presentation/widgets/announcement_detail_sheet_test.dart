import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:hris_mobile/features/home/domain/published_announcement.dart';
import 'package:hris_mobile/features/home/presentation/widgets/announcement_detail_sheet.dart';

import '../../../../fixtures/announcement_list_response.dart';

void main() {
  // Tanggal detail diformat dengan locale id_ID. Di aplikasi ini disiapkan
  // main(); di test harus disiapkan sendiri.
  setUpAll(() => initializeDateFormatting('id_ID'));

  PublishedAnnouncement announcement({
    String title = 'Payroll cut-off pindah ke tanggal 23',
    String? body = 'Klaim lembur disetujui HOD sebelum 23 Sep, 17:00.',
    List<Map<String, dynamic>>? photos,
  }) {
    return PublishedAnnouncement.fromJson(
      announcementListItem(title: title, body: body, photos: photos),
    );
  }

  Future<void> pumpSheet(
    WidgetTester tester,
    PublishedAnnouncement item,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AnnouncementDetailSheet(announcement: item),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('menampilkan judul dan isi lengkap', (tester) async {
    await pumpSheet(tester, announcement());

    expect(find.text('Payroll cut-off pindah ke tanggal 23'), findsOneWidget);
    expect(
      find.text('Klaim lembur disetujui HOD sebelum 23 Sep, 17:00.'),
      findsOneWidget,
    );
  });

  testWidgets('menampilkan departemen sebagai tag', (tester) async {
    await pumpSheet(tester, announcement());

    expect(find.text('HR & GA'), findsOneWidget);
  });

  testWidgets('menampilkan nama penerbit', (tester) async {
    await pumpSheet(tester, announcement());

    expect(find.textContaining('Budi Hartono Hasibuan'), findsOneWidget);
  });

  testWidgets('menampilkan tanggal terbit lengkap, bukan waktu relatif',
      (tester) async {
    await pumpSheet(tester, announcement());

    // 2026-09-16T10:30:29+07:00
    expect(find.textContaining('16'), findsWidgets);
    expect(find.text('54m ago'), findsNothing);
  });

  testWidgets('tidak menampilkan bagian isi saat pengumuman tanpa body',
      (tester) async {
    await pumpSheet(tester, announcement(body: null));

    expect(find.text('Payroll cut-off pindah ke tanggal 23'), findsOneWidget);
    expect(
      find.text('Klaim lembur disetujui HOD sebelum 23 Sep, 17:00.'),
      findsNothing,
    );
  });

  group('foto', () {
    testWidgets('menampilkan gambar saat pengumuman punya lampiran',
        (tester) async {
      await pumpSheet(tester, announcement());

      expect(find.byType(Image), findsOneWidget);
    });

    testWidgets('tidak membatasi jumlah lampiran seperti kartu daftar',
        (tester) async {
      await pumpSheet(
        tester,
        announcement(
          photos: [
            for (var i = 1; i <= 5; i++)
              {'id': i, 'url': 'https://biieportal.co.id/p$i.jpg'},
          ],
        ),
      );

      // ListView membangun isinya secara malas, jadi foto terakhir hanya
      // bisa dibuktikan ada setelah digulir sampai ke sana.
      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('detail-photo-5')),
        200,
      );

      expect(find.byKey(const ValueKey('detail-photo-5')), findsOneWidget);
    });

    testWidgets('tidak menampilkan area foto saat tidak ada lampiran',
        (tester) async {
      await pumpSheet(tester, announcement(photos: []));

      expect(find.byType(Image), findsNothing);
    });

    testWidgets('melewati foto yang URL-nya tidak bisa dipakai',
        (tester) async {
      await pumpSheet(
        tester,
        announcement(
          photos: [
            {'id': 1, 'url': 'bukan url'},
            {'id': 2, 'url': 'https://biieportal.co.id/b.jpg'},
          ],
        ),
      );

      expect(find.byType(Image), findsOneWidget);
    });
  });

  testWidgets('tombol tutup menutup modal', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => showModalBottomSheet<void>(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (_) =>
                  AnnouncementDetailSheet(announcement: announcement()),
            ),
            child: const Text('buka'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('buka'));
    await tester.pumpAndSettle();
    expect(find.byType(AnnouncementDetailSheet), findsOneWidget);

    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();

    expect(find.byType(AnnouncementDetailSheet), findsNothing);
  });
}
