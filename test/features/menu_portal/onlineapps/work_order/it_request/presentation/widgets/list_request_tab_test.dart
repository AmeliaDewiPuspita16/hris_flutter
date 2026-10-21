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

    // Satu di daftar, satu di tiap counter.
    expect(find.byType(CircularProgressIndicator), findsNWidgets(3));

    await tester.pump(const Duration(milliseconds: 300));
  });

  testWidgets('filter On Waiting aktif secara default dan menampilkan hasil '
      '?status=waiting', (tester) async {
    final harness = ItRequestHarness(
      (url, __) => ok(url.queryParameters['status'] == 'waiting'
          ? itRequestListEnvelope(items: [
              itRequestListItem(
                id: 1,
                description: 'Butuh akses VPN',
                statusCode: 'waiting',
                statusLabel: 'On Waiting',
                requesterName: 'Fadel Satriawan',
                requesterDepartment: 'BDD',
              ),
            ])
          : itRequestListEnvelope(items: [
              itRequestListItem(
                id: 2,
                description: 'Pasang CCTV',
                statusCode: 'progress',
                statusLabel: 'On Progress',
              ),
            ])),
    );

    await pumpTab(tester, harness);
    await settle(tester);

    expect(
      harness.requested.map((u) => u.queryParameters['status']),
      unorderedEquals(['waiting', 'progress']),
    );
    expect(find.text('Butuh akses VPN'), findsOneWidget);
    expect(find.text('Pasang CCTV'), findsNothing);
    expect(find.textContaining('Fadel Satriawan'), findsOneWidget);
  });

  testWidgets('counter memakai meta.total dari server, bukan jumlah item yang '
      'termuat', (tester) async {
    final harness = ItRequestHarness(
      (url, __) => ok(url.queryParameters['status'] == 'waiting'
          ? itRequestListEnvelope(
              items: [itRequestListItem(id: 1, statusCode: 'waiting')],
              lastPage: 5,
              total: 91,
            )
          : itRequestListEnvelope(
              items: [itRequestListItem(id: 2, statusCode: 'progress')],
              lastPage: 2,
              total: 21,
            )),
    );

    await pumpTab(tester, harness);
    await settle(tester);

    expect(find.text('91'), findsOneWidget);
    expect(find.text('21'), findsOneWidget);
    expect(harness.requested, hasLength(2), reason: 'tidak menarik semua halaman');
  });

  testWidgets('menekan counter On Progress memindahkan filter ke on progress',
      (tester) async {
    final harness = ItRequestHarness(
      (url, __) => ok(url.queryParameters['status'] == 'waiting'
          ? itRequestListEnvelope(items: [
              itRequestListItem(
                id: 1,
                description: 'Butuh akses VPN',
                statusCode: 'waiting',
                statusLabel: 'On Waiting',
              ),
            ])
          : itRequestListEnvelope(items: [
              itRequestListItem(
                id: 2,
                description: 'Pasang CCTV',
                statusCode: 'progress',
                statusLabel: 'On Progress',
              ),
            ])),
    );

    await pumpTab(tester, harness);
    await settle(tester);

    await tester.tap(find.text('On Progress'));
    await tester.pump();

    expect(find.text('Pasang CCTV'), findsOneWidget);
    expect(find.text('Butuh akses VPN'), findsNothing);
  });

  testWidgets('daftar kosong menampilkan "No data"', (tester) async {
    final harness = ItRequestHarness(
      (_, __) => ok(itRequestListEnvelope(items: const [], total: 0)),
    );

    await pumpTab(tester, harness);
    await settle(tester);

    expect(find.text('No data'), findsOneWidget);
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
      if (url.queryParameters['status'] == 'progress') {
        return ok(itRequestListEnvelope(items: const [], total: 0));
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
        total: 1,
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
    expect(find.text('0'), findsOneWidget, reason: 'counter On Waiting turun');
    expect(find.text('1'), findsOneWidget, reason: 'counter On Progress naik');

    await tester.tap(find.text('On Progress'));
    await tester.pump();

    expect(find.textContaining('Fadel Satriawan'), findsOneWidget);
  });
}
