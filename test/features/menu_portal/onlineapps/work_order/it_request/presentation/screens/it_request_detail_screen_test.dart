import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:hris_mobile/features/menu_portal/onlineapps/work_order/it_request/domain/it_request_detail.dart';
import 'package:hris_mobile/features/menu_portal/onlineapps/work_order/it_request/domain/it_request_item.dart';
import 'package:hris_mobile/features/menu_portal/onlineapps/work_order/it_request/presentation/screens/it_request_detail_screen.dart';
import 'package:hris_mobile/features/menu_portal/onlineapps/work_order/it_request/presentation/widgets/it_request_complete_sheet.dart';
import 'package:hris_mobile/features/menu_portal/onlineapps/work_order/it_request/presentation/widgets/it_request_respond_sheet.dart';

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

  Future<void> pumpScreenForItTeam(
    WidgetTester tester,
    ItRequestHarness harness, {
    required ValueChanged<ItRequestDetail> onItTeamActionDone,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ItRequestDetailScreen(
          item: summary,
          repository: harness.repository,
          onItTeamActionDone: onItTeamActionDone,
        ),
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

  group('action bar tim IT (onItTeamActionDone)', () {
    testWidgets(
        'tanpa onItTeamActionDone, status waiting tidak menampilkan tombol Respond '
        '(mis. dibuka lewat riwayat milik sendiri)', (tester) async {
      await pumpScreen(
        tester,
        detailHarness(itRequestDetail(statusCode: 'waiting', statusLabel: 'On Waiting')),
      );
      await settle(tester);

      expect(find.text('Respond'), findsNothing);
    });

    testWidgets('status waiting menampilkan tombol Respond', (tester) async {
      await pumpScreenForItTeam(
        tester,
        detailHarness(itRequestDetail(statusCode: 'waiting', statusLabel: 'On Waiting')),
        onItTeamActionDone: (_) {},
      );
      await settle(tester);

      expect(find.text('Respond'), findsOneWidget);
      expect(find.text('Complete Request'), findsNothing);
    });

    testWidgets('status progress menampilkan tombol Complete Request', (tester) async {
      await pumpScreenForItTeam(
        tester,
        detailHarness(itRequestDetail(statusCode: 'progress', statusLabel: 'On Progress')),
        onItTeamActionDone: (_) {},
      );
      await settle(tester);

      expect(find.text('Complete Request'), findsOneWidget);
      expect(find.text('Respond'), findsNothing);
    });

    testWidgets('status finished tidak menampilkan aksi tim IT apa pun',
        (tester) async {
      await pumpScreenForItTeam(
        tester,
        detailHarness(itRequestDetail(statusCode: 'finished', statusLabel: 'Finished')),
        onItTeamActionDone: (_) {},
      );
      await settle(tester);

      expect(find.text('Respond'), findsNothing);
      expect(find.text('Complete Request'), findsNothing);
    });

    testWidgets(
        'menekan Respond, submit, memperbarui badge jadi On Progress dan '
        'memanggil onItTeamActionDone', (tester) async {
      ItRequestDetail? callbackResult;
      final harness = ItRequestHarness((url, __) {
        if (url.path.endsWith('/respond')) {
          return ok({
            'data': itRequestDetail(id: 2395, statusCode: 'progress', statusLabel: 'On Progress'),
          });
        }
        return ok({'data': itRequestDetail(statusCode: 'waiting', statusLabel: 'On Waiting')});
      });

      await pumpScreenForItTeam(
        tester,
        harness,
        onItTeamActionDone: (detail) => callbackResult = detail,
      );
      await settle(tester);

      await tester.tap(find.text('Respond'));
      await tester.pumpAndSettle();

      expect(find.byType(ItRequestRespondSheet), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'Scheduling the installation.');
      await tester.pump();
      await tester.tap(find.widgetWithText(ElevatedButton, 'Submit'));
      await tester.pumpAndSettle();

      expect(find.byType(ItRequestRespondSheet), findsNothing);
      expect(find.text('On Progress'), findsWidgets);
      expect(find.text('Respond'), findsNothing);
      expect(find.text('Complete Request'), findsOneWidget);
      expect(callbackResult, isNotNull);
      expect(callbackResult!.status.code, 'progress');
    });

    testWidgets('menekan Complete Request membuka ItRequestCompleteSheet',
        (tester) async {
      await pumpScreenForItTeam(
        tester,
        detailHarness(itRequestDetail(statusCode: 'progress', statusLabel: 'On Progress')),
        onItTeamActionDone: (_) {},
      );
      await settle(tester);

      await tester.tap(find.text('Complete Request'));
      await tester.pumpAndSettle();

      expect(find.byType(ItRequestCompleteSheet), findsOneWidget);
    });
  });
}
