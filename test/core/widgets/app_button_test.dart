import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hris_mobile/core/widgets/app_button.dart';

void main() {
  Future<void> pumpButton(
    WidgetTester tester, {
    required bool isLoading,
    VoidCallback? onPressed,
  }) {
    return tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AppButton(
            label: 'Sign in',
            isLoading: isLoading,
            onPressed: onPressed,
          ),
        ),
      ),
    );
  }

  testWidgets('menampilkan label saat tidak sedang memuat', (tester) async {
    await pumpButton(tester, isLoading: false, onPressed: () {});

    expect(find.text('Sign in'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('mengganti label dengan indikator saat sedang memuat',
      (tester) async {
    await pumpButton(tester, isLoading: true, onPressed: () {});

    expect(find.text('Sign in'), findsNothing);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('tidak bisa ditekan saat sedang memuat', (tester) async {
    var taps = 0;
    await pumpButton(tester, isLoading: true, onPressed: () => taps++);

    await tester.tap(find.byType(AppButton));
    await tester.pump();

    expect(taps, 0);
  });

  testWidgets('bisa ditekan seperti biasa saat tidak memuat', (tester) async {
    var taps = 0;
    await pumpButton(tester, isLoading: false, onPressed: () => taps++);

    await tester.tap(find.byType(AppButton));
    await tester.pump();

    expect(taps, 1);
  });
}
