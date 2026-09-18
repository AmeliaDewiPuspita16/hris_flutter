import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hris_mobile/features/menu_portal/onlineapps/it_request/presentation/screens/online_apps_screen.dart';
import 'package:hris_mobile/features/menu_portal/onlineapps/procurement/presentation/screens/procurement_page.dart';

void main() {
  testWidgets('membuka Procurement Monitoring dari daftar Online Apps',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(home: OnlineAppsScreen()));

    await tester.tap(find.text('Procurement Monitoring'));
    await tester.pumpAndSettle();

    expect(find.byType(ProcurementPage), findsOneWidget);
  });
}
