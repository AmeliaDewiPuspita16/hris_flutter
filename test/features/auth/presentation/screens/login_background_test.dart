import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hris_mobile/core/theme/app_colors.dart';
import 'package:hris_mobile/core/widgets/app_button.dart';
import 'package:hris_mobile/features/auth/data/auth_repository.dart';
import 'package:hris_mobile/features/auth/presentation/bloc/auth/auth_bloc.dart';
import 'package:hris_mobile/features/auth/presentation/screens/login_screen.dart';
import 'package:hris_mobile/features/auth/presentation/widgets/login_footer.dart';

import '../../../../support/auth_harness.dart';

void main() {
  /// Container yang memasang gambar latar.
  final backgroundFinder = find.byWidgetPredicate(
    (w) =>
        w is Container &&
        w.decoration is BoxDecoration &&
        (w.decoration! as BoxDecoration).image != null,
  );

  DecorationImage backgroundImageOf(WidgetTester tester) {
    final container = tester.widget<Container>(backgroundFinder);
    return (container.decoration! as BoxDecoration).image!;
  }

  Future<void> pumpLoginScreen(WidgetTester tester) {
    final harness = AuthHarness();
    return tester.pumpWidget(
      MaterialApp(
        home: RepositoryProvider<AuthRepository>.value(
          value: harness.repository,
          child: BlocProvider.value(
            value: AuthBloc(repository: harness.repository),
            child: const LoginScreen(),
          ),
        ),
      ),
    );
  }

  /// Layar tinggi supaya konten login lebih pendek dari viewport — kondisi
  /// yang memunculkan ruang kosong di screenshot.
  Future<void> pumpOnTallScreen(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1200, 2400);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);
    await pumpLoginScreen(tester);
  }

  testWidgets('memakai bg_login.png sebagai latar halaman', (tester) async {
    await pumpLoginScreen(tester);

    expect(
      (backgroundImageOf(tester).image as AssetImage).assetName,
      'assets/images/bg_login.png',
    );
  });

  testWidgets('latar menutupi seluruh area tanpa meregang', (tester) async {
    await pumpLoginScreen(tester);

    expect(backgroundImageOf(tester).fit, BoxFit.cover);
  });

  testWidgets('tekstur dibuat transparan supaya teks tetap terbaca',
      (tester) async {
    await pumpLoginScreen(tester);

    final opacity = backgroundImageOf(tester).opacity;

    // Angka pastinya soal selera; yang dijaga di sini cuma bahwa teksturnya
    // jelas diredam dan tidak sampai hilang sama sekali.
    expect(opacity, lessThanOrEqualTo(0.4));
    expect(opacity, greaterThan(0));
  });

  testWidgets('latar memakai gradasi, bukan warna rata', (tester) async {
    await pumpLoginScreen(tester);

    final container = tester.widget<Container>(backgroundFinder);
    final decoration = container.decoration! as BoxDecoration;

    expect(decoration.gradient, AppColors.pageGradient);
    expect(decoration.color, isNull, reason: 'gradient dan color tidak boleh dipasang bersamaan');
  });

  testWidgets('tombol Sign in memakai varian bergradasi', (tester) async {
    await pumpLoginScreen(tester);

    final signIn = tester.widget<AppButton>(
      find.widgetWithText(AppButton, 'Sign in'),
    );

    expect(signIn.variant, AppButtonVariant.primaryGradient);
  });

  testWidgets('latar mengisi seluruh tinggi layar, bukan setinggi konten',
      (tester) async {
    await pumpOnTallScreen(tester);

    expect(
      tester.getSize(backgroundFinder).height,
      tester.getSize(find.byType(Scaffold)).height,
    );
  });

  testWidgets('footer turun ke bawah saat konten lebih pendek dari layar',
      (tester) async {
    await pumpOnTallScreen(tester);

    final screenBottom = tester.getRect(find.byType(Scaffold)).bottom;
    final footerBottom = tester.getRect(find.byType(LoginFooter)).bottom;

    // Menempel di bawah, menyisakan jarak aman — bukan mengambang di tengah.
    expect(screenBottom - footerBottom, lessThan(60));
  });
}
