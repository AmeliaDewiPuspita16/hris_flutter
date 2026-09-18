import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:hris_mobile/features/menu_portal/onlineapps/procurement/domain/purchase_requisition_summary.dart';
import 'package:hris_mobile/features/menu_portal/onlineapps/procurement/presentation/screens/pr_detail_screen.dart';

import '../../../../../../fixtures/eprocurement_response.dart';
import '../../support/procurement_harness.dart';

void main() {
  // Waktu submit/approve diformat dengan locale id_ID. Di aplikasi
  // disiapkan main(); di test harus disiapkan sendiri.
  setUpAll(() => initializeDateFormatting('id_ID'));

  final summary = PurchaseRequisitionSummary.fromJson(
    eprocurementListItem(
      id: 3,
      prNumber: 'PR/HSE/26-08/01',
      statusCode: 'pending_finance',
      statusLabel: 'Pending Finance Manager',
      totalEstimatedAmount: 6900000,
    ),
  );

  Future<void> pumpScreen(
    WidgetTester tester,
    ProcurementHarness harness, {
    List<Uri>? opened,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: PrDetailScreen(
          summary: summary,
          repository: harness.repository,
          openUrl: (uri) async {
            opened?.add(uri);
            return true;
          },
        ),
      ),
    );
  }

  Future<void> settle(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
  }

  ProcurementHarness detailHarness([Map<String, dynamic>? detail]) =>
      ProcurementHarness((_, __) => ok({'data': detail ?? eprocurementDetail()}));

  testWidgets('kepala layar tampil dari ringkasan sebelum rincian datang',
      (tester) async {
    final harness = ProcurementHarness((_, __) async {
      await Future<void>.delayed(const Duration(milliseconds: 200));
      return ok({'data': eprocurementDetail()});
    });

    await pumpScreen(tester, harness);
    await tester.pump();

    expect(find.text('PR/HSE/26-08/01'), findsOneWidget);
    expect(find.text('Rp 6.900.000'), findsWidgets);
    expect(find.text('Pending Finance Manager'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 300));
  });

  testWidgets('menampilkan seluruh baris informasi setelah rincian datang',
      (tester) async {
    await pumpScreen(tester, detailHarness());
    await settle(tester);

    expect(find.text('HSE'), findsOneWidget);
    expect(find.text('Sustainability Performance Engineer'), findsOneWidget);
    expect(find.text('Sarla Intan Cahyani'), findsOneWidget);
    expect(find.text('3 Sep 2026'), findsOneWidget);
  });

  testWidgets('tiap item menyebut jenis dan perhitungan qty kali harga',
      (tester) async {
    await pumpScreen(tester, detailHarness());
    await settle(tester);

    expect(find.text('Bongkar dan pasang boom silinder arm excavator'),
        findsOneWidget);
    expect(find.text('Service'), findsOneWidget);
    expect(find.text('1 set × Rp 3.000.000'), findsOneWidget);
    // GL account dan segment digabung jadi satu baris — keduanya pendek dan
    // selalu muncul bersama.
    expect(find.text('GL 513110 · SVC - MAINT'), findsNWidgets(2));
  });

  testWidgets('menampilkan lampiran beserta ukurannya', (tester) async {
    await pumpScreen(tester, detailHarness());
    await settle(tester);

    expect(find.text('ATTACHMENTS'), findsOneWidget);
    expect(find.text('Attachment perbaikan excavator.pdf'), findsOneWidget);
    expect(find.text('389.57 KB'), findsOneWidget);
  });

  testWidgets('mengetuk lampiran membuka URL dari server', (tester) async {
    final opened = <Uri>[];

    await pumpScreen(tester, detailHarness(), opened: opened);
    await settle(tester);

    final button = find.byIcon(Icons.open_in_new);
    await tester.ensureVisible(button);
    await tester.tap(button);
    await tester.pump();

    expect(
      opened.single.toString(),
      'https://biieportal.co.id/storage/epro/attachments/6by4.pdf',
    );
  });

  testWidgets('menampilkan tahap approval beserta pelakunya', (tester) async {
    await pumpScreen(tester, detailHarness());
    await settle(tester);

    expect(find.text('APPROVAL PROGRESS'), findsOneWidget);
    expect(find.text('Finance Manager'), findsWidgets);
    expect(find.text('Disetujui'), findsOneWidget);
    expect(find.textContaining('Habib Twindy Lubis'), findsOneWidget);
    expect(find.text('Belum diproses'), findsOneWidget);
  });

  testWidgets('menampilkan progress dokumen beserta nomor dokumennya',
      (tester) async {
    await pumpScreen(tester, detailHarness());
    await settle(tester);

    expect(find.text('PROGRESS DOKUMEN'), findsOneWidget);
    expect(find.text('PR Approval'), findsOneWidget);
    expect(find.text('Sedang Berjalan'), findsOneWidget);
    expect(find.text('BIIE/26-08-003'), findsOneWidget);
  });

  testWidgets('alasan penolakan tampil sebagai banner', (tester) async {
    await pumpScreen(
      tester,
      detailHarness(
        eprocurementDetail(rejectionReason: 'Anggaran belum tersedia'),
      ),
    );
    await settle(tester);

    expect(find.text('Anggaran belum tersedia'), findsOneWidget);
  });

  testWidgets('tanpa alasan penolakan, bannernya tidak muncul', (tester) async {
    await pumpScreen(tester, detailHarness());
    await settle(tester);

    expect(find.textContaining('Alasan penolakan'), findsNothing);
  });

  testWidgets('kegagalan memunculkan pesan dan tombol coba lagi',
      (tester) async {
    var attempts = 0;
    final harness = ProcurementHarness((_, __) {
      attempts++;
      if (attempts == 1) return fails(message: 'PR tidak ditemukan.');
      return ok({'data': eprocurementDetail()});
    });

    await pumpScreen(tester, harness);
    await settle(tester);

    expect(find.text('PR tidak ditemukan.'), findsOneWidget);

    await tester.tap(find.text('Coba lagi'));
    await settle(tester);

    expect(find.text('ATTACHMENTS'), findsOneWidget);
  });

  testWidgets('isi detail tidak meluber di layar HP sempit', (tester) async {
    tester.view.physicalSize = const Size(360 * 3, 800 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await pumpScreen(tester, detailHarness());
    await settle(tester);

    expect(tester.takeException(), isNull);
  });
}
