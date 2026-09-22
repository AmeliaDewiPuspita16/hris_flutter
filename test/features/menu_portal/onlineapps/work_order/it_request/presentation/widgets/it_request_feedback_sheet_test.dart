import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:hris_mobile/core/network/api_client.dart';
import 'package:hris_mobile/core/utils/date_formatter.dart';
import 'package:hris_mobile/features/menu_portal/onlineapps/work_order/it_request/data/it_request_repository.dart';
import 'package:hris_mobile/features/menu_portal/onlineapps/work_order/it_request/domain/it_request_detail.dart';
import 'package:hris_mobile/features/menu_portal/onlineapps/work_order/it_request/presentation/widgets/it_request_feedback_sheet.dart';

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
                builder: (_) => ItRequestFeedbackSheet(
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

  final detailWithHandling = ItRequestDetail.fromJson(itRequestDetail(
    id: 123,
    rating: null,
    canRate: true,
  ));

  testWidgets('menampilkan kategori, jenis, dan tanggal diajukan',
      (tester) async {
    await pumpSheet(
      tester,
      detail: detailWithHandling,
      repository: repositoryThat((_) async => http.Response('{}', 200)),
    );

    expect(find.text('IT · Email account'), findsOneWidget);
    expect(
      find.text(DateFormatter.shortDate(detailWithHandling.createdAt)),
      findsOneWidget,
    );
  });

  testWidgets('menampilkan ringkasan pengerjaan saat handling tersedia',
      (tester) async {
    await pumpSheet(
      tester,
      detail: detailWithHandling,
      repository: repositoryThat((_) async => http.Response('{}', 200)),
    );

    expect(find.textContaining('Aditya Yudha Pratama'), findsOneWidget);
    expect(
      find.textContaining('inactive sementara'),
      findsOneWidget,
    );
  });

  testWidgets('tidak menampilkan ringkasan pengerjaan saat handling null',
      (tester) async {
    final withoutHandling = ItRequestDetail.fromJson({
      ...itRequestDetail(id: 123, rating: null, canRate: true),
      'handling': null,
    });

    await pumpSheet(
      tester,
      detail: withoutHandling,
      repository: repositoryThat((_) async => http.Response('{}', 200)),
    );

    expect(find.textContaining('Dikerjakan oleh'), findsNothing);
  });

  testWidgets('label rating berubah sesuai bintang yang dipilih',
      (tester) async {
    await pumpSheet(
      tester,
      detail: detailWithHandling,
      repository: repositoryThat((_) async => http.Response('{}', 200)),
    );

    expect(find.text('Sangat Puas'), findsNothing);

    await tester.tap(find.byIcon(Icons.star_outline_rounded).at(4));
    await tester.pump();
    expect(find.text('Sangat Puas'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.star_rounded).first);
    await tester.pump();
    expect(find.text('Sangat Kecewa'), findsOneWidget);
  });

  testWidgets('tombol kirim nonaktif sebelum bintang dipilih', (tester) async {
    await pumpSheet(
      tester,
      detail: detailWithHandling,
      repository: repositoryThat((_) async => http.Response('{}', 200)),
    );

    final button = tester.widget<ElevatedButton>(
      find.widgetWithText(ElevatedButton, 'Kirim Feedback'),
    );
    expect(button.onPressed, isNull);
  });

  testWidgets(
      'mengirim rating memanggil submitRating dan menutup sheet membawa '
      'detail terbaru', (tester) async {
    http.Request? sent;
    final repository = repositoryThat((request) async {
      sent = request;
      return http.Response(
        jsonEncode({
          'data': itRequestDetail(id: 123, rating: 5, canRate: false),
        }),
        200,
      );
    });

    await pumpSheet(tester, detail: detailWithHandling, repository: repository);

    await tester.tap(find.byIcon(Icons.star_outline_rounded).at(4));
    await tester.pump();
    await tester.enterText(find.byType(TextField), 'Terima kasih!');
    await tester.tap(find.widgetWithText(ElevatedButton, 'Kirim Feedback'));
    await tester.pumpAndSettle();

    expect(sent!.method, 'POST');
    expect(sent!.url.path, '/api/portal/apps/it_request/123/rating');
    final body = jsonDecode(sent!.body) as Map<String, dynamic>;
    expect(body['star'], 5);
    expect(body['message'], 'Terima kasih!');

    expect(sheetOpen, isFalse);
    expect(lastResult, isNotNull);
    expect(lastResult!.rating, 5);
    expect(lastResult!.canRate, isFalse);
  });

  testWidgets('menampilkan spinner selagi mengirim', (tester) async {
    final completer = Completer<http.Response>();
    final repository = repositoryThat((_) => completer.future);

    await pumpSheet(tester, detail: detailWithHandling, repository: repository);

    await tester.tap(find.byIcon(Icons.star_outline_rounded).at(4));
    await tester.pump();
    await tester.tap(find.widgetWithText(ElevatedButton, 'Kirim Feedback'));
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    completer.complete(http.Response(
      jsonEncode({'data': itRequestDetail(id: 123, rating: 5, canRate: false)}),
      200,
    ));
    await tester.pumpAndSettle();
  });

  testWidgets('gagal kirim menampilkan pesan galat dan sheet tetap terbuka',
      (tester) async {
    final repository = repositoryThat(
      (_) async => http.Response(
        jsonEncode({'message': 'Server sibuk, coba lagi.'}),
        500,
      ),
    );

    await pumpSheet(tester, detail: detailWithHandling, repository: repository);

    await tester.tap(find.byIcon(Icons.star_outline_rounded).at(4));
    await tester.pump();
    await tester.tap(find.widgetWithText(ElevatedButton, 'Kirim Feedback'));
    await tester.pumpAndSettle();

    expect(find.text('Server sibuk, coba lagi.'), findsOneWidget);
    expect(find.text('Beri feedback'), findsOneWidget);
    expect(sheetOpen, isTrue);
  });
}
