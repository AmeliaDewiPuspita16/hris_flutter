import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hris_mobile/features/menu_portal/onlineapps/procurement/domain/pr_line_item.dart';
import 'package:hris_mobile/features/menu_portal/onlineapps/procurement/domain/pr_status.dart';
import 'package:hris_mobile/features/menu_portal/onlineapps/procurement/domain/purchase_requisition.dart';
import 'package:hris_mobile/features/menu_portal/onlineapps/procurement/presentation/screens/pr_detail_screen.dart';
import 'package:hris_mobile/features/menu_portal/onlineapps/procurement/presentation/screens/procurement_page.dart';

void main() {
  PurchaseRequisition requisition({
    required String id,
    required String prNumber,
    String section = 'F&B Service',
    String requestor = 'Rindiani',
    String purpose = 'operational Restaurant',
    PrStatus status = PrStatus.pendingHod,
    List<PrLineItem>? items,
  }) =>
      PurchaseRequisition(
        id: id,
        prNumber: prNumber,
        date: DateTime(2026, 9, 18),
        department: 'EVD',
        section: section,
        requestor: requestor,
        requiredDate: DateTime(2026, 9, 17),
        purpose: purpose,
        status: status,
        items: items ??
            const [
              PrLineItem(
                description: 'Tisu evo napkin luncheon 100\'s',
                kind: PrItemKind.goods,
                qty: 5,
                unit: 'BOX',
                estPrice: 453000,
              ),
            ],
      );

  final evd = requisition(id: 'pr-1', prNumber: 'PR/EVD/26-09/10');
  final est = requisition(
    id: 'pr-2',
    prNumber: 'PR/EST/26-09/13',
    section: 'Estate Admin Asssitant',
    requestor: 'Darmawati',
    purpose: 'Melakukan maintenance unit Forklif Power House',
    status: PrStatus.pendingDgm,
  );

  Future<void> pumpPage(
    WidgetTester tester, {
    List<PurchaseRequisition>? requisitions,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ProcurementPage(requisitions: requisitions ?? [evd, est]),
      ),
    );
    await tester.pump();
  }

  testWidgets('menampilkan ringkasan tiap PR di kartunya', (tester) async {
    await pumpPage(tester, requisitions: [evd]);

    expect(find.text('PR/EVD/26-09/10'), findsOneWidget);
    expect(find.text('18 Sep 2026 · F&B Service'), findsOneWidget);
    expect(find.text('Rindiani'), findsOneWidget);
    expect(find.text('operational Restaurant'), findsOneWidget);
    expect(find.text('1 item'), findsOneWidget);
    expect(find.text('Rp 2.265.000'), findsOneWidget);
    expect(find.text('Pending HOD'), findsOneWidget);
  });

  testWidgets('chip filter menyebut jumlah PR per status', (tester) async {
    await pumpPage(tester);

    expect(find.text('Semua (2)'), findsOneWidget);
    expect(find.text('HOD (1)'), findsOneWidget);
    expect(find.text('DGM (1)'), findsOneWidget);
  });

  testWidgets('chip filter hanya memunculkan status yang ada datanya',
      (tester) async {
    await pumpPage(tester, requisitions: [evd]);

    expect(find.text('HOD (1)'), findsOneWidget);
    expect(find.text('DGM (0)'), findsNothing);
    expect(find.text('Rejected (0)'), findsNothing);
  });

  testWidgets('memilih chip status menyisakan PR berstatus itu saja',
      (tester) async {
    await pumpPage(tester);

    await tester.tap(find.text('DGM (1)'));
    await tester.pump();

    expect(find.text('PR/EST/26-09/13'), findsOneWidget);
    expect(find.text('PR/EVD/26-09/10'), findsNothing);
  });

  testWidgets('kolom cari menyaring PR lewat nama requestor', (tester) async {
    await pumpPage(tester);

    await tester.enterText(find.byType(TextField), 'darmawati');
    await tester.pump();

    expect(find.text('PR/EST/26-09/13'), findsOneWidget);
    expect(find.text('PR/EVD/26-09/10'), findsNothing);
  });

  testWidgets('menampilkan "Tidak ada data" saat tidak ada yang cocok',
      (tester) async {
    await pumpPage(tester);

    await tester.enterText(find.byType(TextField), 'tidak ada ini');
    await tester.pump();

    expect(find.text('Tidak ada data'), findsOneWidget);
  });

  testWidgets('jumlah di chip ikut kata kunci, tapi chipnya tidak hilang',
      (tester) async {
    await pumpPage(tester);

    await tester.enterText(find.byType(TextField), 'darmawati');
    await tester.pump();

    expect(find.text('Semua (1)'), findsOneWidget);
    expect(find.text('DGM (1)'), findsOneWidget);
    expect(find.text('HOD (0)'), findsOneWidget);
  });

  testWidgets('kartu tidak meluber di layar HP sempit', (tester) async {
    tester.view.physicalSize = const Size(360 * 3, 800 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    // Pakai data contoh sungguhan: di sanalah nama section dan purpose
    // terpanjang berada.
    await tester.pumpWidget(const MaterialApp(home: ProcurementPage()));
    await tester.pump();

    expect(tester.takeException(), isNull);
  });

  testWidgets('mengetuk kartu membuka halaman detail PR', (tester) async {
    await pumpPage(tester);

    await tester.tap(find.text('PR/EVD/26-09/10'));
    await tester.pumpAndSettle();

    expect(find.byType(PrDetailScreen), findsOneWidget);
  });
}
