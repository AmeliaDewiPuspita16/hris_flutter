import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hris_mobile/core/widgets/user_avatar.dart';

void main() {
  Future<void> pump(WidgetTester tester, Widget child) async {
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: child)));
  }

  testWidgets('menampilkan inisial saat photoUrl null', (tester) async {
    await pump(tester, const UserAvatar(initials: 'AP', fontSize: 15));

    expect(find.text('AP'), findsOneWidget);
    expect(find.byType(Image), findsNothing);
  });

  testWidgets('menampilkan foto dari photoUrl saat tersedia', (tester) async {
    const url = 'https://biieportal.co.id/storage/profile/foto.jpg';

    await pump(
      tester,
      const UserAvatar(initials: 'AP', photoUrl: url, fontSize: 15),
    );

    final image = tester.widget<Image>(find.byType(Image));
    expect((image.image as NetworkImage).url, url);
  });
}
