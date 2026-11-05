import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hris_mobile/core/widgets/screen_capture_guard.dart';
import 'package:no_screenshot/constants.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const methods = MethodChannel(screenshotMethodChannel);
  const events = MethodChannel(screenshotEventChannel);
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  late List<String> calls;
  late Future<Object?> Function(String method) respond;

  /// Mengirim event plugin ke Dart, seperti saat status perekaman berubah.
  Future<void> emitRecording(WidgetTester tester, bool isRecording) async {
    await messenger.handlePlatformMessage(
      screenshotEventChannel,
      const StandardMethodCodec().encodeSuccessEnvelope(
        jsonEncode({'is_screen_recording': isRecording}),
      ),
      (_) {},
    );
    await tester.pump();
  }

  Widget guarded() => const MaterialApp(
    home: Scaffold(body: ScreenCaptureGuard(child: Text('isi dokumen'))),
  );

  setUp(() {
    calls = [];
    respond = (_) async => true;
    messenger.setMockMethodCallHandler(methods, (call) {
      calls.add(call.method);
      return respond(call.method);
    });
    messenger.setMockMethodCallHandler(events, (_) async => null);
  });

  tearDown(() {
    messenger.setMockMethodCallHandler(methods, null);
    messenger.setMockMethodCallHandler(events, null);
  });

  testWidgets('dokumen baru tampil setelah proteksi selesai dipasang', (
    tester,
  ) async {
    final protection = Completer<Object?>();
    respond = (method) =>
        method == screenShotOffConst ? protection.future : Future.value(true);

    await tester.pumpWidget(guarded());
    await tester.pump();
    expect(calls, contains(screenShotOffConst));
    expect(find.text('isi dokumen'), findsNothing);

    protection.complete(true);
    await tester.pumpAndSettle();
    expect(find.text('isi dokumen'), findsOneWidget);
  });

  testWidgets('proteksi dilepas saat layar ditutup', (tester) async {
    await tester.pumpWidget(guarded());
    await tester.pumpAndSettle();
    expect(calls, isNot(contains(screenShotOnConst)));

    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
    expect(
      calls,
      containsAll([screenShotOnConst, stopScreenRecordingListeningConst]),
    );
  });

  testWidgets('dokumen disembunyikan selama layar direkam', (tester) async {
    await tester.pumpWidget(guarded());
    await tester.pumpAndSettle();
    expect(calls, contains(startScreenRecordingListeningConst));

    await emitRecording(tester, true);
    expect(find.text('isi dokumen'), findsNothing);
    expect(find.textContaining('screen recording'), findsOneWidget);

    await emitRecording(tester, false);
    expect(find.text('isi dokumen'), findsOneWidget);
  });

  testWidgets('kegagalan plugin tidak menghalangi membaca dokumen', (
    tester,
  ) async {
    respond = (_) async => throw PlatformException(code: 'gagal');

    await tester.pumpWidget(guarded());
    await tester.pumpAndSettle();
    expect(find.text('isi dokumen'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  test('sisa proteksi dari sesi yang mati mendadak dibersihkan', () async {
    await ScreenCaptureGuard.clearLeftoverProtection();
    expect(calls, [screenShotOnConst]);
  });
}
