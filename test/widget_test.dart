import 'package:flutter_test/flutter_test.dart';
import 'package:hris_mobile/features/auth/domain/auth_session.dart';
import 'package:hris_mobile/features/auth/presentation/screens/login_screen.dart';
import 'package:hris_mobile/features/home/presentation/screens/beranda_screen.dart';
import 'package:hris_mobile/features/splash/presentation/screens/splash_screen.dart';
import 'package:hris_mobile/main.dart';

import 'fixtures/login_response.dart';
import 'support/auth_harness.dart';

void main() {
  testWidgets('aplikasi membuka layar splash lebih dulu', (tester) async {
    await tester.pumpWidget(MyApp(authRepository: AuthHarness().repository));

    expect(find.byType(SplashScreen), findsOneWidget);

    await tester.pump(SplashScreen.displayDuration);
    await tester.pumpAndSettle();
  });

  testWidgets('berlanjut ke login saat belum ada sesi tersimpan',
      (tester) async {
    await tester.pumpWidget(MyApp(authRepository: AuthHarness().repository));

    await tester.pump(SplashScreen.displayDuration);
    await tester.pumpAndSettle();

    expect(find.byType(LoginScreen), findsOneWidget);
  });

  testWidgets('langsung ke beranda saat sesi sebelumnya masih tersimpan',
      (tester) async {
    final harness = AuthHarness();
    harness.storage.session = AuthSession.fromJson(loginResponseData());

    await tester.pumpWidget(MyApp(authRepository: harness.repository));
    await tester.pump(SplashScreen.displayDuration);
    await tester.pumpAndSettle();

    expect(find.byType(BerandaScreen), findsOneWidget);
    expect(find.byType(LoginScreen), findsNothing);
  });
}
