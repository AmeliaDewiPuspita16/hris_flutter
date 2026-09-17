import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:hris_mobile/core/network/api_client.dart';
import 'package:hris_mobile/core/network/api_exception.dart';
import 'package:hris_mobile/core/widgets/app_button.dart';
import 'package:hris_mobile/features/home/domain/announcement.dart';
import 'package:hris_mobile/features/home/domain/announcement_photo.dart';
import 'package:hris_mobile/features/home/presentation/widgets/create_announcement_sheet.dart';
import 'package:hris_mobile/features/shared/data/department_repository.dart';

import '../../../../support/recording_announcement_repository.dart';

void main() {
  /// Repository departemen yang selalu berhasil, supaya dropdown-nya terisi.
  DepartmentRepository departmentRepository() {
    return DepartmentRepository(
      apiClient: ApiClient(
        httpClient: MockClient(
          (_) async => http.Response(
            jsonEncode({
              'data': [
                {'id': 8, 'name': 'HR & GA'},
                {'id': 17, 'name': 'ITM'},
              ],
            }),
            200,
          ),
        ),
      ),
    );
  }

  AnnouncementPhoto photo(String name) => AnnouncementPhoto(
        path: '/tmp/$name',
        fileName: name,
        sizeBytes: 1024,
      );

  Announcement? lastResult;

  /// Membuka sheet lewat showModalBottomSheet supaya Navigator.pop membawa
  /// hasilnya persis seperti di Beranda.
  Future<void> pumpSheet(
    WidgetTester tester, {
    required RecordingAnnouncementRepository announcements,
    PhotoPicker? pickPhotos,
  }) async {
    lastResult = null;

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () async {
              lastResult = await showModalBottomSheet<Announcement>(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (_) => CreateAnnouncementSheet(
                  departmentRepository: departmentRepository(),
                  announcementRepository: announcements,
                  pickPhotos: pickPhotos,
                ),
              );
            },
            child: const Text('buka'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('buka'));
    await tester.pumpAndSettle();
  }

  Future<void> fillTitle(
    WidgetTester tester, {
    String title = 'Judul uji',
  }) async {
    await tester.enterText(find.byType(TextField).first, title);
    await tester.pump();
  }

  Future<void> tapPost(WidgetTester tester) async {
    await tester.tap(find.widgetWithText(AppButton, 'Post Announcement'));
  }

  Future<void> tapAddPhoto(WidgetTester tester) async {
    await tester.tap(find.text('Tambah foto'));
    await tester.pumpAndSettle();
  }

  group('mengirim', () {
    testWidgets('tidak memanggil server saat judul masih kosong',
        (tester) async {
      final repository = RecordingAnnouncementRepository();
      await pumpSheet(tester, announcements: repository);

      await tapPost(tester);
      await tester.pump();

      expect(repository.calls, 0);
      expect(find.text('Title is required'), findsOneWidget);
    });

    testWidgets('meneruskan department, judul, dan isi ke repository',
        (tester) async {
      final repository = RecordingAnnouncementRepository();
      await pumpSheet(tester, announcements: repository);

      await fillTitle(tester, title: 'Payroll cut-off');
      await tester.enterText(find.byType(TextField).last, 'Isi pengumuman');
      await tapPost(tester);
      await tester.pumpAndSettle();

      expect(repository.calls, 1);
      expect(repository.lastDepartmentId, 8);
      expect(repository.lastTitle, 'Payroll cut-off');
      expect(repository.lastBody, 'Isi pengumuman');
    });

    testWidgets('menampilkan indikator pada tombol selagi mengirim',
        (tester) async {
      final release = Completer<void>();
      final repository =
          RecordingAnnouncementRepository(hold: release.future);
      await pumpSheet(tester, announcements: repository);

      await fillTitle(tester);
      await tapPost(tester);
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Post Announcement'), findsNothing);

      release.complete();
      await tester.pumpAndSettle();
    });

    testWidgets('tombol tidak bisa ditekan lagi selagi pengiriman berjalan',
        (tester) async {
      final release = Completer<void>();
      final repository =
          RecordingAnnouncementRepository(hold: release.future);
      await pumpSheet(tester, announcements: repository);

      await fillTitle(tester);
      await tapPost(tester);
      await tester.pump();

      // Dicari lewat tipe, bukan teks: labelnya sedang diganti indikator.
      await tester.tap(find.byType(AppButton), warnIfMissed: false);
      await tester.pump();

      expect(repository.calls, 1);

      release.complete();
      await tester.pumpAndSettle();
    });

    testWidgets('menutup sheet membawa pengumuman dari respons server',
        (tester) async {
      final repository = RecordingAnnouncementRepository();
      await pumpSheet(tester, announcements: repository);

      await fillTitle(tester, title: 'judul dari form');
      await tapPost(tester);
      await tester.pumpAndSettle();

      // Judul yang dipakai berasal dari server, bukan dari isian form.
      expect(lastResult, isNotNull);
      expect(lastResult!.title, 'Payroll cut-off pindah ke tanggal 23');
      expect(lastResult!.tag.label, 'HR & GA');
    });
  });

  group('galat', () {
    testWidgets('menampilkan pesan server tanpa menutup sheet', (tester) async {
      final repository = RecordingAnnouncementRepository(
        failure: const ApiException(
          ApiErrorKind.badRequest,
          'The selected department id is invalid.',
        ),
      );
      await pumpSheet(tester, announcements: repository);

      await fillTitle(tester);
      await tapPost(tester);
      await tester.pumpAndSettle();

      expect(
        find.text('The selected department id is invalid.'),
        findsOneWidget,
      );
      expect(find.text('New Announcement'), findsOneWidget);
      expect(lastResult, isNull);
    });

    testWidgets('mengembalikan tombol ke keadaan semula setelah gagal',
        (tester) async {
      final repository = RecordingAnnouncementRepository(
        failure: const ApiException.network(),
      );
      await pumpSheet(tester, announcements: repository);

      await fillTitle(tester);
      await tapPost(tester);
      await tester.pumpAndSettle();

      expect(find.text('Post Announcement'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('membersihkan pesan galat saat mencoba lagi', (tester) async {
      final release = Completer<void>();
      final repository = RecordingAnnouncementRepository(
        failure: const ApiException.network(),
        failOnlyFirstCall: true,
        hold: release.future,
      );
      await pumpSheet(tester, announcements: repository);

      await fillTitle(tester);
      await tapPost(tester);
      await tester.pumpAndSettle();
      expect(find.textContaining('koneksi internet'), findsOneWidget);

      await tapPost(tester);
      await tester.pump();

      expect(find.textContaining('koneksi internet'), findsNothing);
      expect(repository.calls, 2);

      release.complete();
      await tester.pumpAndSettle();
    });
  });

  group('foto', () {
    testWidgets('menampilkan foto yang baru dipilih', (tester) async {
      await pumpSheet(
        tester,
        announcements: RecordingAnnouncementRepository(),
        pickPhotos: () async => [photo('poster1.jpg'), photo('poster2.png')],
      );

      await tapAddPhoto(tester);

      expect(find.byKey(const ValueKey('photo-poster1.jpg')), findsOneWidget);
      expect(find.byKey(const ValueKey('photo-poster2.png')), findsOneWidget);
    });

    testWidgets('menghapus foto yang dipilih', (tester) async {
      await pumpSheet(
        tester,
        announcements: RecordingAnnouncementRepository(),
        pickPhotos: () async => [photo('poster1.jpg'), photo('poster2.png')],
      );
      await tapAddPhoto(tester);

      await tester.tap(find.byKey(const ValueKey('remove-poster1.jpg')));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('photo-poster1.jpg')), findsNothing);
      expect(find.byKey(const ValueKey('photo-poster2.png')), findsOneWidget);
    });

    testWidgets('menolak pilihan yang melebihi 10 foto', (tester) async {
      await pumpSheet(
        tester,
        announcements: RecordingAnnouncementRepository(),
        pickPhotos: () async =>
            List.generate(11, (i) => photo('poster$i.jpg')),
      );

      await tapAddPhoto(tester);

      expect(find.textContaining('Maksimal 10 foto'), findsOneWidget);
      expect(find.byKey(const ValueKey('photo-poster0.jpg')), findsNothing);
    });

    testWidgets('menolak format selain JPG dan PNG', (tester) async {
      await pumpSheet(
        tester,
        announcements: RecordingAnnouncementRepository(),
        pickPhotos: () async => [photo('dokumen.pdf')],
      );

      await tapAddPhoto(tester);

      expect(find.textContaining('dokumen.pdf'), findsOneWidget);
      expect(find.byKey(const ValueKey('photo-dokumen.pdf')), findsNothing);
    });

    testWidgets('meneruskan foto terpilih ke repository', (tester) async {
      final repository = RecordingAnnouncementRepository();
      await pumpSheet(
        tester,
        announcements: repository,
        pickPhotos: () async => [photo('poster1.jpg')],
      );

      await tapAddPhoto(tester);
      await fillTitle(tester);
      await tapPost(tester);
      await tester.pumpAndSettle();

      expect(repository.lastPhotos, hasLength(1));
      expect(repository.lastPhotos.single.fileName, 'poster1.jpg');
    });

    testWidgets('tidak meneruskan foto yang sudah dihapus', (tester) async {
      final repository = RecordingAnnouncementRepository();
      await pumpSheet(
        tester,
        announcements: repository,
        pickPhotos: () async => [photo('poster1.jpg'), photo('poster2.png')],
      );

      await tapAddPhoto(tester);
      await tester.tap(find.byKey(const ValueKey('remove-poster1.jpg')));
      await tester.pumpAndSettle();
      await fillTitle(tester);
      await tapPost(tester);
      await tester.pumpAndSettle();

      expect(repository.lastPhotos.single.fileName, 'poster2.png');
    });

    testWidgets('memberi pesan ramah saat galeri tidak bisa dibuka',
        (tester) async {
      await pumpSheet(
        tester,
        announcements: RecordingAnnouncementRepository(),
        pickPhotos: () async => throw Exception('PlatformException(channel)'),
      );

      await tapAddPhoto(tester);

      expect(find.text('Tidak bisa membuka galeri.'), findsOneWidget);
      expect(find.textContaining('PlatformException'), findsNothing);
    });
  });
}
