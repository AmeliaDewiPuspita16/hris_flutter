import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:hris_mobile/features/menu_portal/onlineapps/work_order/it_request/domain/it_request_item.dart';
import 'package:hris_mobile/features/menu_portal/onlineapps/work_order/it_request/presentation/screens/it_request_detail_screen.dart';

import '../../../../../../../fixtures/it_request_response.dart';
import '../../support/it_request_harness.dart';

void main() {
  setUpAll(() => initializeDateFormatting('id_ID'));

  final summary = ItRequestItem.fromJson(itRequestListItem());

  Future<void> pumpScreen(WidgetTester tester, ItRequestHarness harness) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ItRequestDetailScreen(item: summary, repository: harness.repository),
      ),
    );
  }

  Future<void> settle(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
  }

  ItRequestHarness detailHarness([Map<String, dynamic>? detail]) =>
      ItRequestHarness((_, __) => ok({'data': detail ?? itRequestDetail()}));

  testWidgets('kepala layar tampil dari item sebelum rincian datang', (tester) async {
    final harness = ItRequestHarness((_, __) async {
      await Future<void>.delayed(const Duration(milliseconds: 200));
      return ok({'data': itRequestDetail()});
    });

    await pumpScreen(tester, harness);
    await tester.pump();

    expect(find.text('Email account'), findsOneWidget);
    expect(find.text('Finished'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 300));
  });

  testWidgets('menampilkan requester setelah rincian datang', (tester) async {
    await pumpScreen(tester, detailHarness());
    await settle(tester);

    expect(find.text('Frida Khaerani'), findsOneWidget);
    expect(find.text('HR & GA'), findsOneWidget);
  });

  testWidgets('menampilkan rincian pengerjaan', (tester) async {
    await pumpScreen(tester, detailHarness());
    await settle(tester);

    expect(find.text('Aditya Yudha Pratama'), findsOneWidget);
    expect(
      find.textContaining('Kak ini aku buat akun Rifki Ananta'),
      findsOneWidget,
    );
  });

  testWidgets('menampilkan rating dan komentarnya', (tester) async {
    await pumpScreen(tester, detailHarness());
    await settle(tester);

    expect(find.text('thank youu'), findsOneWidget);
  });

  testWidgets('alasan pembatalan tampil sebagai banner bila terisi', (tester) async {
    await pumpScreen(
      tester,
      detailHarness(itRequestDetail(cancelReason: 'Sudah tidak dibutuhkan')),
    );
    await settle(tester);

    expect(find.text('Sudah tidak dibutuhkan'), findsOneWidget);
  });

  testWidgets('tanpa alasan pembatalan, bannernya tidak muncul', (tester) async {
    await pumpScreen(tester, detailHarness());
    await settle(tester);

    expect(find.textContaining('Alasan pembatalan'), findsNothing);
  });

  testWidgets('kegagalan memunculkan pesan dan tombol coba lagi', (tester) async {
    var attempts = 0;
    final harness = ItRequestHarness((_, __) {
      attempts++;
      if (attempts == 1) return fails(message: 'Request tidak ditemukan.');
      return ok({'data': itRequestDetail()});
    });

    await pumpScreen(tester, harness);
    await settle(tester);

    expect(find.text('Request tidak ditemukan.'), findsOneWidget);

    await tester.tap(find.text('Coba lagi'));
    await settle(tester);

    expect(find.text('Frida Khaerani'), findsOneWidget);
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
