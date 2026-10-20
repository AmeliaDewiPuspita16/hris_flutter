import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:hris_mobile/core/network/api_client.dart';
import 'package:hris_mobile/features/menu_portal/onlineapps/work_order/it_request/data/it_request_repository.dart';
import 'package:hris_mobile/features/menu_portal/onlineapps/work_order/it_request/domain/it_request_detail.dart';
import 'package:hris_mobile/features/menu_portal/onlineapps/work_order/it_request/presentation/widgets/it_request_respond_sheet.dart';

import '../../../../../../../fixtures/it_request_response.dart';

void main() {
  ItRequestRepository repositoryThat(
    Future<http.Response> Function(http.Request request) respond,
  ) {
    return ItRequestRepository(
      apiClient: ApiClient(httpClient: MockClient(respond)),
    );
  }

  ItRequestDetail? lastResult;
  bool sheetOpen = true;

  Future<void> pumpSheet(
    WidgetTester tester, {
    required ItRequestDetail detail,
    required ItRequestRepository repository,
  }) async {
    lastResult = null;
    sheetOpen = true;

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () async {
              lastResult = await showModalBottomSheet<ItRequestDetail>(
                context: context,
                isScrollControlled: true,
                builder: (_) => ItRequestRespondSheet(
                  detail: detail,
                  repository: repository,
                ),
              );
              sheetOpen = false;
            },
            child: const Text('open'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  final waitingDetail = ItRequestDetail.fromJson(itRequestDetail(
    id: 123,
    statusCode: 'waiting',
    statusLabel: 'On Waiting',
    rating: null,
    canRate: false,
  ));

  testWidgets('menampilkan requester dan deskripsi request', (tester) async {
    await pumpSheet(
      tester,
      detail: waitingDetail,
      repository: repositoryThat((_) async => http.Response('{}', 200)),
    );

    expect(find.textContaining('Frida Khaerani'), findsOneWidget);
    expect(find.textContaining(waitingDetail.description), findsOneWidget);
  });

  testWidgets('tombol Submit nonaktif sebelum catatan diisi', (tester) async {
    await pumpSheet(
      tester,
      detail: waitingDetail,
      repository: repositoryThat((_) async => http.Response('{}', 200)),
    );

    final button = tester.widget<ElevatedButton>(
      find.widgetWithText(ElevatedButton, 'Submit'),
    );
    expect(button.onPressed, isNull);
  });

  testWidgets(
      'mengirim respon memanggil endpoint respond dan menutup sheet membawa '
      'detail terbaru (status jadi on progress)', (tester) async {
    http.Request? sent;
    final repository = repositoryThat((request) async {
      sent = request;
      return http.Response(
        jsonEncode({
          'data': itRequestDetail(id: 123, statusCode: 'progress', statusLabel: 'On Progress'),
        }),
        200,
      );
    });

    await pumpSheet(tester, detail: waitingDetail, repository: repository);

    await tester.enterText(
      find.byType(TextField),
      'Scheduling the installation for tomorrow morning.',
    );
    await tester.pump();
    await tester.tap(find.widgetWithText(ElevatedButton, 'Submit'));
    await tester.pumpAndSettle();

    expect(sent!.method, 'POST');
    expect(sent!.url.path, '/api/portal/apps/it_request/123/respond');
    final body = jsonDecode(sent!.body) as Map<String, dynamic>;
    expect(body['note'], 'Scheduling the installation for tomorrow morning.');

    expect(sheetOpen, isFalse);
    expect(lastResult, isNotNull);
    expect(lastResult!.status.code, 'progress');
  });

  testWidgets('menampilkan spinner selagi mengirim', (tester) async {
    final completer = Completer<http.Response>();
    final repository = repositoryThat((_) => completer.future);

    await pumpSheet(tester, detail: waitingDetail, repository: repository);

    await tester.enterText(find.byType(TextField), 'Sedang dijadwalkan.');
    await tester.pump();
    await tester.tap(find.widgetWithText(ElevatedButton, 'Submit'));
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    completer.complete(http.Response(
      jsonEncode({'data': itRequestDetail(id: 123, statusCode: 'progress')}),
      200,
    ));
    await tester.pumpAndSettle();
  });

  testWidgets('gagal kirim menampilkan pesan galat dan sheet tetap terbuka',
      (tester) async {
    final repository = repositoryThat(
      (_) async => http.Response(
        jsonEncode({'message': 'Please write a response before updating the status.'}),
        422,
      ),
    );

    await pumpSheet(tester, detail: waitingDetail, repository: repository);

    await tester.enterText(find.byType(TextField), 'Sedang dijadwalkan.');
    await tester.pump();
    await tester.tap(find.widgetWithText(ElevatedButton, 'Submit'));
    await tester.pumpAndSettle();

    expect(find.text('Please write a response before updating the status.'), findsOneWidget);
    expect(find.text('Respond Request'), findsOneWidget);
    expect(sheetOpen, isTrue);
  });
}
