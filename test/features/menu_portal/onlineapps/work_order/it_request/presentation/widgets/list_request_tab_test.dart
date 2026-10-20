import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:hris_mobile/features/menu_portal/onlineapps/work_order/it_request/data/it_request_repository.dart';
import 'package:hris_mobile/features/menu_portal/onlineapps/work_order/it_request/presentation/screens/it_request_detail_screen.dart';
import 'package:hris_mobile/features/menu_portal/onlineapps/work_order/it_request/presentation/widgets/list_request_tab.dart';

import '../../../../../../../fixtures/it_request_response.dart';
import '../../support/it_request_harness.dart';

void main() {
  setUpAll(() => initializeDateFormatting('id_ID'));

  Future<void> pumpTab(WidgetTester tester, ItRequestHarness harness) async {
    await tester.pumpWidget(
      RepositoryProvider<ItRequestRepository>.value(
        value: harness.repository,
        // ListRequestTab tidak membawa Scaffold sendiri — di app sungguhan
        // ia hidup di dalam Scaffold milik ItRequestScreen (lih. IndexedStack
        // di sana).
        child: const MaterialApp(home: Scaffold(body: ListRequestTab())),
      ),
    );
  }

  Future<void> settle(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
  }

  testWidgets('menampilkan spinner selagi memuat pertama kali', (tester) async {
    final harness = ItRequestHarness((_, __) async {
      await Future<void>.delayed(const Duration(milliseconds: 200));
      return ok(itRequestListEnvelope());
    });

    await pumpTab(tester, harness);
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 300));
  });

  testWidgets('filter On Waiting aktif secara default dan hanya menampilkan '
      'item berstatus waiting', (tester) async {
    final harness = ItRequestHarness(
      (_, __) => ok(itRequestListEnvelope(
        items: [
          itRequestListItem(
            id: 1,
            description: 'Butuh akses VPN',
            statusCode: 'waiting',
            statusLabel: 'On Waiting',
            requesterName: 'Fadel Satriawan',
            requesterDepartment: 'BDD',
          ),
          itRequestListItem(
            id: 2,
            description: 'Pasang CCTV',
            statusCode: 'progress',
            statusLabel: 'On Progress',
            requesterName: 'Frida Khaerani',
            requesterDepartment: 'HR & GA',
          ),
        ],
      )),
    );

    await pumpTab(tester, harness);
    await settle(tester);

    expect(find.text('Butuh akses VPN'), findsOneWidget);
    expect(find.text('Pasang CCTV'), findsNothing);
    expect(find.textContaining('Fadel Satriawan'), findsOneWidget);
  });

  testWidgets('counter On Waiting/On Progress menghitung item yang termuat',
      (tester) async {
    final harness = ItRequestHarness(
      (_, __) => ok(itRequestListEnvelope(
        items: [
          itRequestListItem(id: 1, statusCode: 'waiting', statusLabel: 'On Waiting'),
          itRequestListItem(id: 2, statusCode: 'waiting', statusLabel: 'On Waiting'),
          itRequestListItem(id: 3, statusCode: 'progress', statusLabel: 'On Progress'),
        ],
      )),
    );

    await pumpTab(tester, harness);
    await settle(tester);

    expect(find.text('2'), findsOneWidget);
    expect(find.text('1'), findsOneWidget);
  });

  testWidgets(
      'counter menghitung total sebenarnya dari semua halaman, bukan cuma '
      'halaman pertama (regresi: dulu angkanya terus bertambah tiap scroll)',
      (tester) async {
    final harness = ItRequestHarness((url, __) {
      final page = int.parse(url.queryParameters['page'] ?? '1');
      return ok(itRequestListEnvelope(
        items: [itRequestListItem(id: page, statusCode: 'waiting', statusLabel: 'On Waiting')],
        currentPage: page,
        lastPage: 3,
      ));
    });

    await pumpTab(tester, harness);
    await settle(tester);

    // Seluruh 3 halaman (3 item) sudah ditarik otomatis saat tab dibuka,
    // tanpa perlu scroll sama sekali.
    expect(harness.requested, hasLength(3));
    expect(find.text('3'), findsOneWidget);

    // Angkanya tidak berubah lagi walau di-scroll — sudah final/akurat,
    // bukan "sejauh yang sudah termuat sampai sekarang".
    await tester.drag(find.byType(ListView), const Offset(0, -2000));
    await settle(tester);

    expect(harness.requested, hasLength(3));
    expect(find.text('3'), findsOneWidget);
  });

  testWidgets(
      'selagi halaman tersisa masih ditarik, counter menampilkan spinner — '
      'bukan angka parsial yang berubah-ubah tiap halaman masuk',
      (tester) async {
    final harness = ItRequestHarness((url, __) async {
      final page = int.parse(url.queryParameters['page'] ?? '1');
      // Delay di halaman ke-2 dan seterusnya supaya ada jeda nyata untuk
      // diperiksa di tengah proses "tarik semua halaman".
      if (page > 1) await Future<void>.delayed(const Duration(milliseconds: 50));
      return ok(itRequestListEnvelope(
        items: [itRequestListItem(id: page, statusCode: 'waiting', statusLabel: 'On Waiting')],
        currentPage: page,
        lastPage: 3,
      ));
    });

    await pumpTab(tester, harness);
    // Halaman pertama saja yang sudah selesai (1 item) — halaman 2 & 3
    // masih berjalan di latar belakang.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 10));

    expect(find.text('1'), findsNothing, reason: 'angka parsial tidak boleh tampil');
    expect(find.byType(CircularProgressIndicator), findsWidgets);

    await settle(tester);
    await tester.pump(const Duration(milliseconds: 150));

    expect(find.text('3'), findsOneWidget);
  });

  testWidgets('menekan counter On Progress memindahkan filter ke on progress',
      (tester) async {
    final harness = ItRequestHarness(
      (_, __) => ok(itRequestListEnvelope(
        items: [
          itRequestListItem(
            id: 1,
            description: 'Butuh akses VPN',
            statusCode: 'waiting',
            statusLabel: 'On Waiting',
          ),
          itRequestListItem(
            id: 2,
            description: 'Pasang CCTV',
            statusCode: 'progress',
            statusLabel: 'On Progress',
          ),
        ],
      )),
    );

    await pumpTab(tester, harness);
    await settle(tester);

    await tester.tap(find.text('On Progress'));
    await tester.pump();

    expect(find.text('Pasang CCTV'), findsOneWidget);
    expect(find.text('Butuh akses VPN'), findsNothing);
  });

  testWidgets('tidak ada item sesuai filter menampilkan "Tidak ada data"',
      (tester) async {
    final harness = ItRequestHarness(
      (_, __) => ok(itRequestListEnvelope(
        items: [itRequestListItem(id: 1, statusCode: 'finished', statusLabel: 'Finished')],
      )),
    );

    await pumpTab(tester, harness);
    await settle(tester);

    expect(find.text('Tidak ada data'), findsOneWidget);
  });

  testWidgets('mengetuk baris membuka layar detail dengan aksi tim IT aktif',
      (tester) async {
    final harness = ItRequestHarness((url, __) {
      if (url.path.endsWith('/2395')) {
        return ok({
          'data': itRequestDetail(id: 2395, statusCode: 'waiting', statusLabel: 'On Waiting'),
        });
      }
      return ok(itRequestListEnvelope(
        items: [
          itRequestListItem(
            id: 2395,
            description: 'Butuh akses VPN',
            statusCode: 'waiting',
            statusLabel: 'On Waiting',
          ),
        ],
      ));
    });

    await pumpTab(tester, harness);
    await settle(tester);

    await tester.tap(find.text('Butuh akses VPN'));
    await tester.pumpAndSettle();

    expect(find.byType(ItRequestDetailScreen), findsOneWidget);
    expect(find.text('Respond'), findsOneWidget);
  });

  testWidgets('respond di layar detail langsung memindahkan item ke daftar '
      'on progress tanpa reload', (tester) async {
    final harness = ItRequestHarness((url, __) {
      if (url.path.endsWith('/respond')) {
        return ok({
          'data': itRequestDetail(
            id: 2395,
            statusCode: 'progress',
            statusLabel: 'On Progress',
            requesterName: 'Fadel Satriawan',
          ),
        });
      }
      if (url.path.endsWith('/2395')) {
        return ok({
          'data': itRequestDetail(
            id: 2395,
            statusCode: 'waiting',
            statusLabel: 'On Waiting',
            requesterName: 'Fadel Satriawan',
          ),
        });
      }
      return ok(itRequestListEnvelope(
        items: [
          itRequestListItem(
            id: 2395,
            requesterName: 'Fadel Satriawan',
            statusCode: 'waiting',
            statusLabel: 'On Waiting',
          ),
        ],
      ));
    });

    await pumpTab(tester, harness);
    await settle(tester);

    await tester.tap(find.textContaining('Fadel Satriawan'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Respond'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Sedang dikerjakan.');
    await tester.pump();
    await tester.tap(find.widgetWithText(ElevatedButton, 'Submit'));
    await tester.pumpAndSettle();

    // BackHeader pakai InkWell+Icon kustom, bukan AppBar bawaan, jadi
    // tester.pageBack() (yang mencari BackButton) tidak menemukannya.
    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();

    expect(
      find.textContaining('Fadel Satriawan'),
      findsNothing,
      reason: 'tidak lagi di filter On Waiting',
    );

    await tester.tap(find.text('On Progress'));
    await tester.pump();

    expect(find.textContaining('Fadel Satriawan'), findsOneWidget);
  });
}
