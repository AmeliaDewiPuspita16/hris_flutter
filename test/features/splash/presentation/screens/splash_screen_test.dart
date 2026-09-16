import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hris_mobile/features/splash/presentation/screens/splash_screen.dart';

void main() {
  testWidgets('menampilkan logo BIE dari assets', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: SplashScreen()));

    final logo = tester.widget<Image>(find.byType(Image));

    expect((logo.image as AssetImage).assetName, 'assets/images/bie.png');
  });

  testWidgets('tidak lagi memakai huruf B sebagai pengganti logo',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(home: SplashScreen()));

    expect(find.text('B'), findsNothing);
  });

  testWidgets('logo diberi keterangan untuk pembaca layar', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: SplashScreen()));

    final logo = tester.widget<Image>(find.byType(Image));

    expect(logo.semanticLabel, isNotNull);
  });
}
