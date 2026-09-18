import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hris_mobile/features/menu_portal/onlineapps/procurement/domain/approval_step.dart';
import 'package:hris_mobile/features/menu_portal/onlineapps/procurement/domain/document_stage.dart';
import 'package:hris_mobile/features/menu_portal/onlineapps/procurement/domain/pr_attachment.dart';
import 'package:hris_mobile/features/menu_portal/onlineapps/procurement/domain/pr_line_item.dart';
import 'package:hris_mobile/features/menu_portal/onlineapps/procurement/domain/pr_status.dart';
import 'package:hris_mobile/features/menu_portal/onlineapps/procurement/domain/procurement_demo_data.dart';
import 'package:hris_mobile/features/menu_portal/onlineapps/procurement/domain/progress_state.dart';
import 'package:hris_mobile/features/menu_portal/onlineapps/procurement/domain/purchase_requisition.dart';
import 'package:hris_mobile/features/menu_portal/onlineapps/procurement/presentation/screens/pr_detail_screen.dart';

void main() {
  PurchaseRequisition requisition({
    List<PrLineItem>? items,
    List<PrAttachment> attachments = const [
      PrAttachment(
        fileName: "Tisu evo napkin luncheon 100's.xlsx",
        sizeLabel: '720.94 KB',
      ),
    ],
  }) =>
      PurchaseRequisition(
        id: 'pr-1',
        prNumber: 'PR/EVD/26-09/10',
        date: DateTime(2026, 9, 18),
        department: 'EVD',
        section: 'F&B Service',
        requestor: 'Rindiani',
        requiredDate: DateTime(2026, 9, 17),
        purpose: 'operational Restaurant',
        status: PrStatus.pendingHod,
        items: items ??
            const [
              PrLineItem(
                description: "Tisu evo napkin luncheon 100's",
                kind: PrItemKind.goods,
                qty: 5,
                unit: 'BOX',
                estPrice: 453000,
              ),
            ],
        attachments: attachments,
        approvalSteps: const [
          ApprovalStep(
            title: 'HOD Approval',
            note: 'Menunggu persetujuan',
            state: ProgressState.current,
          ),
          ApprovalStep(
            title: 'GM Approval',
            note: 'Belum diproses',
            state: ProgressState.pending,
          ),
        ],
        documentStages: const [
          DocumentStage(
            title: 'PR Approval',
            statusLabel: 'Sedang Berjalan',
            state: ProgressState.current,
            subSteps: [
              DocumentSubStep(
                label: 'HOD',
                note: 'Menunggu persetujuan',
                state: ProgressState.current,
              ),
              DocumentSubStep(label: 'DGM', state: ProgressState.pending),
            ],
          ),
          DocumentStage(
            title: 'Goods Receipt',
            statusLabel: 'Belum ada',
            state: ProgressState.pending,
          ),
        ],
      );

  Future<void> pumpScreen(WidgetTester tester, PurchaseRequisition pr) async {
    await tester.pumpWidget(
      MaterialApp(home: PrDetailScreen(requisition: pr)),
    );
    await tester.pump();
  }

  testWidgets('kepala layar memuat nomor PR, est. total, dan status',
      (tester) async {
    await pumpScreen(tester, requisition());

    expect(find.text('PR/EVD/26-09/10'), findsOneWidget);
    expect(find.text('Est. Total'), findsOneWidget);
    expect(find.text('Rp 2.265.000'), findsWidgets);
    expect(find.text('Pending HOD'), findsOneWidget);
  });

  testWidgets('menampilkan seluruh baris informasi PR', (tester) async {
    await pumpScreen(tester, requisition());

    expect(find.text('18 Sep 2026'), findsOneWidget);
    expect(find.text('EVD'), findsOneWidget);
    expect(find.text('F&B Service'), findsOneWidget);
    expect(find.text('Rindiani'), findsOneWidget);
    expect(find.text('17 Sep 2026'), findsOneWidget);
  });

  testWidgets('menampilkan purpose', (tester) async {
    await pumpScreen(tester, requisition());

    expect(find.text('operational Restaurant'), findsOneWidget);
  });

  testWidgets('tiap item menyebut jenis dan perhitungan qty kali harga satuan',
      (tester) async {
    await pumpScreen(tester, requisition());

    expect(find.text("Tisu evo napkin luncheon 100's"), findsOneWidget);
    expect(find.text('Goods'), findsOneWidget);
    expect(find.text('5 BOX × Rp 453.000'), findsOneWidget);
  });

  testWidgets('subtotal tiap item ditampilkan', (tester) async {
    await pumpScreen(
      tester,
      requisition(
        items: const [
          PrLineItem(
            description: 'Filter hidrolik forklift',
            kind: PrItemKind.goods,
            qty: 2,
            unit: 'PCS',
            estPrice: 385000,
          ),
        ],
      ),
    );

    expect(find.text('Rp 770.000'), findsWidgets);
  });

  testWidgets('GL Account ditampilkan bila item punya nomornya', (tester) async {
    await pumpScreen(
      tester,
      requisition(
        items: const [
          PrLineItem(
            description: 'Jasa service berkala forklift',
            kind: PrItemKind.service,
            glAccount: '6210-0031',
            qty: 1,
            unit: 'JOB',
            estPrice: 4750000,
          ),
        ],
      ),
    );

    expect(find.text('GL 6210-0031'), findsOneWidget);
  });

  testWidgets('baris GL Account dilewati bila item tidak punya nomornya',
      (tester) async {
    await pumpScreen(tester, requisition());

    expect(find.textContaining('GL '), findsNothing);
  });

  testWidgets('menampilkan lampiran beserta ukurannya', (tester) async {
    await pumpScreen(tester, requisition());

    expect(find.text('ATTACHMENTS'), findsOneWidget);
    expect(find.text("Tisu evo napkin luncheon 100's.xlsx"), findsOneWidget);
    expect(find.text('720.94 KB'), findsOneWidget);
  });

  testWidgets('bagian lampiran disembunyikan bila PR tidak punya lampiran',
      (tester) async {
    await pumpScreen(tester, requisition(attachments: const []));

    expect(find.text('ATTACHMENTS'), findsNothing);
  });

  testWidgets('menampilkan tahap approval beserta keterangannya',
      (tester) async {
    await pumpScreen(tester, requisition());

    expect(find.text('APPROVAL PROGRESS'), findsOneWidget);
    expect(find.text('HOD Approval'), findsOneWidget);
    expect(find.text('Menunggu persetujuan'), findsWidgets);
    expect(find.text('GM Approval'), findsOneWidget);
    expect(find.text('Belum diproses'), findsOneWidget);
  });

  testWidgets('menampilkan progress dokumen beserta rinciannya',
      (tester) async {
    await pumpScreen(tester, requisition());

    expect(find.text('PROGRESS DOKUMEN'), findsOneWidget);
    expect(find.text('PR Approval'), findsOneWidget);
    expect(find.text('Sedang Berjalan'), findsOneWidget);
    expect(find.text('DGM'), findsOneWidget);
    expect(find.text('Goods Receipt'), findsOneWidget);
    expect(find.text('Belum ada'), findsOneWidget);
  });

  testWidgets('isi detail tidak meluber di layar HP sempit', (tester) async {
    tester.view.physicalSize = const Size(360 * 3, 800 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    // Semua PR contoh dicoba: nama section, purpose, dan nominal terpanjang
    // tersebar di beberapa baris berbeda.
    for (final pr in ProcurementDemoData.items()) {
      await pumpScreen(tester, pr);
      expect(tester.takeException(), isNull, reason: pr.prNumber);
    }
  });

  testWidgets('Export PDF memberi tahu bahwa fiturnya belum tersedia',
      (tester) async {
    await pumpScreen(tester, requisition());

    await tester.tap(find.byIcon(Icons.picture_as_pdf_outlined));
    await tester.pump();

    expect(find.textContaining('belum tersedia'), findsOneWidget);
  });

  testWidgets('unduh lampiran memberi tahu bahwa fiturnya belum tersedia',
      (tester) async {
    await pumpScreen(tester, requisition());

    final download = find.byIcon(Icons.file_download_outlined);
    await tester.ensureVisible(download);
    await tester.tap(download);
    await tester.pump();

    expect(find.textContaining('belum tersedia'), findsOneWidget);
  });
}
