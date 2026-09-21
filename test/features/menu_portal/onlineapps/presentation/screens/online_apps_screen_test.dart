import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hris_mobile/features/menu_portal/onlineapps/presentation/screens/online_apps_screen.dart';
import 'package:hris_mobile/features/menu_portal/onlineapps/procurement/data/procurement_repository.dart';
import 'package:hris_mobile/features/menu_portal/onlineapps/procurement/presentation/screens/procurement_page.dart';

import '../../../../../fixtures/eprocurement_response.dart';
import '../../procurement/support/procurement_harness.dart';

void main() {
  testWidgets('membuka Procurement Monitoring dari daftar Online Apps',
      (tester) async {
    // ProcurementPage mengambil repository-nya dari provider, sama seperti
    // di aplikasi — di sana disediakan main().
    final harness = ProcurementHarness((_, __) => ok(eprocurementListEnvelope()));

    await tester.pumpWidget(
      RepositoryProvider<ProcurementRepository>.value(
        value: harness.repository,
        child: const MaterialApp(home: OnlineAppsScreen()),
      ),
    );

    await tester.tap(find.text('Procurement Monitoring'));
    await tester.pumpAndSettle();

    expect(find.byType(ProcurementPage), findsOneWidget);
  });
}
