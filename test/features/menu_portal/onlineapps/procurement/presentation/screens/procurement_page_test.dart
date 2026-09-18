import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:hris_mobile/features/menu_portal/onlineapps/procurement/presentation/screens/pr_detail_screen.dart';
import 'package:hris_mobile/features/menu_portal/onlineapps/procurement/presentation/screens/procurement_page.dart';

import '../../../../../../fixtures/eprocurement_response.dart';
import '../../support/procurement_harness.dart';

void main() {
  // Layar detail memformat tanggal dengan locale id_ID. Di aplikasi
  // disiapkan main(); di test harus disiapkan sendiri.
  setUpAll(() => initializeDateFormatting('id_ID'));

  Future<void> pumpPage(WidgetTester tester, ProcurementHarness harness) async {
    await tester.pumpWidget(
      MaterialApp(home: ProcurementPage(repository: harness.repository)),
    );
  }

  /// Menunggu request pertama selesai dan hasilnya tergambar.
  Future<void> settle(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
  }

  testWidgets('menampilkan spinner selagi memuat pertama kali', (tester) async {
    final harness = ProcurementHarness((_, __) async {
      await Future<void>.delayed(const Duration(milliseconds: 200));
      return ok(eprocurementListEnvelope());
    });

    await pumpPage(tester, harness);
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 300));
  });

  testWidgets('menampilkan kartu PR dari server', (tester) async {
    final harness = ProcurementHarness((_, __) => ok(eprocurementListEnvelope()));

    await pumpPage(tester, harness);
    await settle(tester);

    expect(find.text('PR/AML/26-09/01'), findsOneWidget);
    expect(find.text('Rika Susila Susanti'), findsOneWidget);
    expect(find.text('Rp 2.938.005.000'), findsOneWidget);
    expect(find.text('Pending Review'), findsOneWidget);
  });

  testWidgets('chip filter menyebut jumlah dari ringkasan server',
      (tester) async {
    final harness = ProcurementHarness((_, __) => ok(eprocurementListEnvelope()));

    await pumpPage(tester, harness);
    await settle(tester);

    expect(find.text('Semua (9)'), findsOneWidget);
    expect(find.text('Under Review (3)'), findsOneWidget);
    expect(find.text('DGM (0)'), findsOneWidget);
  });

  testWidgets('menekan chip mengirim filter status ke server', (tester) async {
    final harness = ProcurementHarness((_, __) => ok(eprocurementListEnvelope()));

    await pumpPage(tester, harness);
    await settle(tester);

    await tester.tap(find.text('HOD (1)'));
    await settle(tester);

    expect(harness.lastRequest.queryParameters['status'], 'pending_hod');
  });

  testWidgets('mengetik di kolom cari mengirim kata kunci setelah jeda',
      (tester) async {
    final harness = ProcurementHarness((_, __) => ok(eprocurementListEnvelope()));

    await pumpPage(tester, harness);
    await settle(tester);

    await tester.enterText(find.byType(TextField), 'forklift');
    await tester.pump(const Duration(milliseconds: 100));

    // Belum lewat jeda ketik — belum ada request kedua.
    expect(harness.requested, hasLength(1));

    await tester.pump(const Duration(milliseconds: 500));
    await settle(tester);

    expect(harness.lastRequest.queryParameters['search'], 'forklift');
  });

  testWidgets('kegagalan memunculkan pesan dan tombol coba lagi',
      (tester) async {
    var attempts = 0;
    final harness = ProcurementHarness((_, __) {
      attempts++;
      if (attempts == 1) return fails(message: 'Server sibuk');
      return ok(eprocurementListEnvelope());
    });

    await pumpPage(tester, harness);
    await settle(tester);

    expect(find.text('Server sibuk'), findsOneWidget);

    await tester.tap(find.text('Coba lagi'));
    await settle(tester);

    expect(find.text('PR/AML/26-09/01'), findsOneWidget);
  });

  testWidgets('menampilkan "Tidak ada data" saat server tidak mengirim PR',
      (tester) async {
    final harness = ProcurementHarness(
      (_, __) => ok(eprocurementListEnvelope(items: const [])),
    );

    await pumpPage(tester, harness);
    await settle(tester);

    expect(find.text('Tidak ada data'), findsOneWidget);
  });

  testWidgets('mengetuk kartu membuka halaman detail PR', (tester) async {
    final harness = ProcurementHarness((url, __) {
      if (url.path.endsWith('/9')) return ok({'data': eprocurementDetail()});
      return ok(eprocurementListEnvelope());
    });

    await pumpPage(tester, harness);
    await settle(tester);

    await tester.tap(find.text('PR/AML/26-09/01'));
    await tester.pumpAndSettle();

    expect(find.byType(PrDetailScreen), findsOneWidget);
  });

  testWidgets('kartu tidak meluber di layar HP sempit', (tester) async {
    tester.view.physicalSize = const Size(360 * 3, 800 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final harness = ProcurementHarness((_, __) => ok(eprocurementListEnvelope()));

    await pumpPage(tester, harness);
    await settle(tester);

    expect(tester.takeException(), isNull);
  });
}
