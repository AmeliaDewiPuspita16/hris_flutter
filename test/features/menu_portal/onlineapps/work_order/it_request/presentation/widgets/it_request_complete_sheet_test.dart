import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:hris_mobile/core/network/api_client.dart';
import 'package:hris_mobile/features/menu_portal/onlineapps/work_order/it_request/data/it_request_repository.dart';
import 'package:hris_mobile/features/menu_portal/onlineapps/work_order/it_request/domain/it_request_attachment.dart';
import 'package:hris_mobile/features/menu_portal/onlineapps/work_order/it_request/domain/it_request_detail.dart';
import 'package:hris_mobile/features/menu_portal/onlineapps/work_order/it_request/presentation/widgets/it_request_complete_sheet.dart';

import '../../../../../../../fixtures/it_request_response.dart';

void main() {
  // Multipart (lih. ItRequestCompleteSheet -> ApiClient.postMultipart) wajib
  // berkas sungguhan di disk — MultipartFile.fromPath gagal sebelum sempat
  // menyentuh mock HTTP client kalau path-nya tidak ada. Pola sama dengan
  // it_request_submit_test.dart/it_request_complete_test.dart.
  late Directory tempDir;
  late ItRequestAttachment photo;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('it_request_complete_sheet_test');
    final file = File('${tempDir.path}/done.jpg');
    await file.writeAsBytes([1, 2, 3, 4]);
    photo = ItRequestAttachment(path: file.path, fileName: 'done.jpg', sizeBytes: 4);
  });

  tearDown(() async {
    if (tempDir.existsSync()) await tempDir.delete(recursive: true);
  });

  ItRequestRepository repositoryThat(MockClientStreamHandler respond) {
    return ItRequestRepository(
      apiClient: ApiClient(httpClient: MockClient.streaming(respond)),
    );
  }

  Future<http.StreamedResponse> jsonResponse(Map<String, dynamic> body, {int statusCode = 200}) async =>
      http.StreamedResponse(Stream.value(utf8.encode(jsonEncode(body))), statusCode);

  ItRequestDetail? lastResult;
  bool sheetOpen = true;

  Future<void> pumpSheet(
    WidgetTester tester, {
    required ItRequestDetail detail,
    required ItRequestRepository repository,
    AttachmentPicker? pickAttachment,
  }) async {
    lastResult = null;
    sheetOpen = true;

    // Sheet ini lebih panjang dari feedback sheet (dua text field + field
    // foto) — layar uji default menyembunyikan tombol submit di bawah
    // lipatan, jadi tap langsung ke posisinya tidak kena.
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () async {
              lastResult = await showModalBottomSheet<ItRequestDetail>(
                context: context,
                isScrollControlled: true,
                builder: (_) => ItRequestCompleteSheet(
                  detail: detail,
                  repository: repository,
                  pickAttachment: pickAttachment,
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

  final progressDetail = ItRequestDetail.fromJson(itRequestDetail(
    id: 123,
    statusCode: 'progress',
    statusLabel: 'On Progress',
    rating: null,
    canRate: false,
  ));

  testWidgets('menampilkan requester dan deskripsi request', (tester) async {
    await pumpSheet(
      tester,
      detail: progressDetail,
      repository: repositoryThat((_, __) => jsonResponse(const {})),
    );

    expect(find.textContaining('Frida Khaerani'), findsOneWidget);
    expect(find.textContaining(progressDetail.description), findsOneWidget);
  });

  testWidgets('tombol Complete Request nonaktif sebelum foto dipilih',
      (tester) async {
    await pumpSheet(
      tester,
      detail: progressDetail,
      repository: repositoryThat((_, __) => jsonResponse(const {})),
    );

    final button = tester.widget<ElevatedButton>(
      find.widgetWithText(ElevatedButton, 'Complete Request'),
    );
    expect(button.onPressed, isNull);
  });

  testWidgets('memilih foto menampilkan nama berkas dan mengaktifkan tombol',
      (tester) async {
    await pumpSheet(
      tester,
      detail: progressDetail,
      repository: repositoryThat((_, __) => jsonResponse(const {})),
      pickAttachment: () async => photo,
    );

    await tester.tap(find.text('Click to select photo evidence'));
    await tester.pumpAndSettle();

    expect(find.text('done.jpg'), findsOneWidget);
    final button = tester.widget<ElevatedButton>(
      find.widgetWithText(ElevatedButton, 'Complete Request'),
    );
    expect(button.onPressed, isNotNull);
  });

  testWidgets('foto dengan ekstensi tidak didukung ditolak dengan pesan galat',
      (tester) async {
    await pumpSheet(
      tester,
      detail: progressDetail,
      repository: repositoryThat((_, __) => jsonResponse(const {})),
      pickAttachment: () async => const ItRequestAttachment(
        path: '/tmp/dokumen.pdf',
        fileName: 'dokumen.pdf',
        sizeBytes: 1024,
      ),
    );

    await tester.tap(find.text('Click to select photo evidence'));
    await tester.pumpAndSettle();

    expect(find.textContaining('harus JPG, JPEG, PNG'), findsOneWidget);
    final button = tester.widget<ElevatedButton>(
      find.widgetWithText(ElevatedButton, 'Complete Request'),
    );
    expect(button.onPressed, isNull);
  });

  testWidgets(
      'menyelesaikan request memanggil endpoint complete dengan foto dan '
      'catatan, lalu menutup sheet membawa detail terbaru (wait_checked)',
      (tester) async {
    http.BaseRequest? sent;
    String? sentBody;
    final repository = repositoryThat((request, bodyStream) async {
      sent = request;
      sentBody = utf8.decode(await bodyStream.toBytes());
      return jsonResponse({
        'data': itRequestDetail(id: 123, statusCode: 'wait_checked', statusLabel: 'Wait Checked'),
      });
    });

    await pumpSheet(
      tester,
      detail: progressDetail,
      repository: repository,
      pickAttachment: () async => photo,
    );

    await tester.tap(find.text('Click to select photo evidence'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Wifi installed and tested.');
    await tester.pump();

    final completeButton = find.widgetWithText(ElevatedButton, 'Complete Request');
    final buttonBefore = tester.widget<ElevatedButton>(completeButton);
    expect(buttonBefore.onPressed, isNotNull, reason: 'tombol harus aktif setelah foto dipilih');

    // MultipartFile.fromPath membaca berkas sungguhan lewat dart:io — di
    // widget test, itu butuh runAsync supaya I/O-nya benar-benar jalan,
    // bukan cuma pump() yang cuma memajukan microtask/timer palsu. Delay
    // singkat di akhir blok memberi event loop sungguhan kesempatan
    // menyelesaikan rantai await-nya sebelum blok runAsync ditutup.
    await tester.runAsync(() async {
      await tester.tap(completeButton);
      await Future<void>.delayed(const Duration(milliseconds: 100));
    });
    await tester.pumpAndSettle();

    expect(sent!.method, 'POST');
    expect(sent!.url.path, '/api/portal/apps/it_request/123/complete');
    expect(sentBody, contains('name="photo"'));
    expect(sentBody, contains('name="note"'));

    expect(sheetOpen, isFalse);
    expect(lastResult, isNotNull);
    expect(lastResult!.status.code, 'wait_checked');
  });

  testWidgets('menampilkan spinner selagi mengirim', (tester) async {
    // Delay sungguhan di dalam SATU blok runAsync yang sama (bukan Completer
    // yang diselesaikan terpisah dari luar runAsync) — kelanjutan async yang
    // terikat ke zone sungguhan dari satu runAsync tidak lanjut diproses
    // begitu blok itu selesai, jadi tidak bisa "dibangunkan lagi" dari
    // runAsync terpisah berikutnya.
    final repository = repositoryThat((_, __) async {
      await Future<void>.delayed(const Duration(milliseconds: 150));
      return jsonResponse({'data': itRequestDetail(id: 123, statusCode: 'wait_checked')});
    });

    await pumpSheet(
      tester,
      detail: progressDetail,
      repository: repository,
      pickAttachment: () async => photo,
    );

    await tester.tap(find.text('Click to select photo evidence'));
    await tester.pumpAndSettle();

    await tester.runAsync(() async {
      await tester.tap(find.widgetWithText(ElevatedButton, 'Complete Request'));
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      await Future<void>.delayed(const Duration(milliseconds: 250));
    });
    await tester.pumpAndSettle();

    expect(sheetOpen, isFalse);
  });

  testWidgets('gagal kirim menampilkan pesan galat dan sheet tetap terbuka',
      (tester) async {
    final repository = repositoryThat(
      (_, __) => jsonResponse(
        const {'message': 'The photo field is required.'},
        statusCode: 422,
      ),
    );

    await pumpSheet(
      tester,
      detail: progressDetail,
      repository: repository,
      pickAttachment: () async => photo,
    );

    await tester.tap(find.text('Click to select photo evidence'));
    await tester.pumpAndSettle();
    await tester.runAsync(() async {
      await tester.tap(find.widgetWithText(ElevatedButton, 'Complete Request'));
      await Future<void>.delayed(const Duration(milliseconds: 100));
    });
    await tester.pumpAndSettle();

    expect(find.text('The photo field is required.'), findsOneWidget);
    expect(find.text('Finish Request'), findsOneWidget);
    expect(sheetOpen, isTrue);
  });
}
