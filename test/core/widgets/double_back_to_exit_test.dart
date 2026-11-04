import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hris_mobile/core/widgets/double_back_to_exit.dart';

void main() {
  late List<MethodCall> platformCalls;

  setUp(() {
    platformCalls = [];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
      platformCalls.add(call);
      return null;
    });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null);
  });

  bool exited() => platformCalls.any((c) => c.method == 'SystemNavigator.pop');

  Future<void> pump(WidgetTester tester, {bool Function()? onBack}) =>
      tester.pumpWidget(
        MaterialApp(
          home: DoubleBackToExit(
            onBack: onBack,
            child: const Scaffold(body: Text('Home')),
          ),
        ),
      );

  Future<void> pressBack(WidgetTester tester) async {
    await tester.binding.handlePopRoute();
    await tester.pump();
  }

  testWidgets('back pertama hanya memberi petunjuk, tidak keluar',
      (tester) async {
    await pump(tester);

    await pressBack(tester);

    expect(find.text('Press back again to exit'), findsOneWidget);
    expect(exited(), isFalse);
  });

  testWidgets('back kedua dalam 2 detik menutup aplikasi', (tester) async {
    await pump(tester);

    await pressBack(tester);
    await pressBack(tester);

    expect(exited(), isTrue);
  });

  testWidgets('back kedua setelah lewat 2 detik hanya memberi petunjuk lagi',
      (tester) async {
    await pump(tester);

    await pressBack(tester);
    await tester.pump(const Duration(seconds: 3));
    // DateTime.now() tidak ikut waktu palsu test; tunggu sungguhan.
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 2100)),
    );
    await pressBack(tester);

    expect(exited(), isFalse);
    expect(find.text('Press back again to exit'), findsOneWidget);
  });

  testWidgets('onBack yang menangani back (mis. pindah ke Home) tidak keluar',
      (tester) async {
    var onOtherTab = true;
    await pump(tester, onBack: () {
      if (!onOtherTab) return false;
      onOtherTab = false;
      return true;
    });

    await pressBack(tester);
    expect(onOtherTab, isFalse);
    expect(find.text('Press back again to exit'), findsNothing);

    await pressBack(tester);
    await pressBack(tester);
    expect(exited(), isTrue);
  });
}
