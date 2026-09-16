import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hris_mobile/core/theme/app_colors.dart';
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

  group('varian bergradasi', () {
    Future<void> pumpVariant(
      WidgetTester tester,
      AppButtonVariant variant, {
      bool isLoading = false,
      bool enabled = true,
      VoidCallback? onPressed,
    }) {
      return tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppButton(
              label: 'Sign in',
              variant: variant,
              isLoading: isLoading,
              enabled: enabled,
              onPressed: onPressed ?? () {},
            ),
          ),
        ),
      );
    }

    /// Gradasi pertama yang terpasang di pohon widget tombol.
    Gradient? gradientIn(WidgetTester tester) {
      final gradients = tester
          .widgetList<DecoratedBox>(find.byType(DecoratedBox))
          .map((d) => d.decoration)
          .whereType<BoxDecoration>()
          .map((d) => d.gradient)
          .whereType<Gradient>();

      return gradients.isEmpty ? null : gradients.first;
    }

    testWidgets('primaryGradient memakai gradasi hijau dari palet',
        (tester) async {
      await pumpVariant(tester, AppButtonVariant.primaryGradient);

      expect(gradientIn(tester), AppColors.primaryGradient);
    });

    testWidgets('varian primary tetap warna rata tanpa gradasi',
        (tester) async {
      await pumpVariant(tester, AppButtonVariant.primary);

      expect(gradientIn(tester), isNull);
    });

    testWidgets('melepas gradasi saat tombol nonaktif', (tester) async {
      await pumpVariant(
        tester,
        AppButtonVariant.primaryGradient,
        enabled: false,
      );

      expect(gradientIn(tester), isNull);
    });

    testWidgets('melepas gradasi selagi memuat', (tester) async {
      await pumpVariant(
        tester,
        AppButtonVariant.primaryGradient,
        isLoading: true,
      );

      expect(gradientIn(tester), isNull);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('tetap bisa ditekan seperti varian lain', (tester) async {
      var taps = 0;
      await pumpVariant(
        tester,
        AppButtonVariant.primaryGradient,
        onPressed: () => taps++,
      );

      await tester.tap(find.byType(AppButton));
      await tester.pump();

      expect(taps, 1);
    });
  });
}
