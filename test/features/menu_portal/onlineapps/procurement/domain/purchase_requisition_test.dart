import 'package:flutter_test/flutter_test.dart';
import 'package:hris_mobile/features/menu_portal/onlineapps/procurement/domain/approval_state.dart';
import 'package:hris_mobile/features/menu_portal/onlineapps/procurement/domain/document_state.dart';
import 'package:hris_mobile/features/menu_portal/onlineapps/procurement/domain/pr_line_item.dart';
import 'package:hris_mobile/features/menu_portal/onlineapps/procurement/domain/purchase_requisition.dart';
import 'package:hris_mobile/features/menu_portal/onlineapps/procurement/domain/purchase_requisition_summary.dart';

import '../../../../../fixtures/eprocurement_response.dart';

void main() {
  group('PurchaseRequisitionSummary.fromJson', () {
    test('memetakan satu baris daftar PR', () {
      final pr = PurchaseRequisitionSummary.fromJson(eprocurementListItem());

      expect(pr.id, 9);
      expect(pr.prNumber, 'PR/AML/26-09/01');
      expect(pr.prDate, DateTime(2026, 9, 1));
      expect(pr.section, 'Admin Legal');
      expect(pr.requestor, 'Rika Susila Susanti');
      expect(pr.purpose, 'Retribusi Persetujuan Bangunan Gedung (PBG)');
      expect(pr.itemsCount, 1);
      expect(pr.totalEstimatedAmount, 2938005000);
      expect(pr.status.label, 'Pending Review');
    });

    test('itemCountLabel memakai bentuk tunggal untuk satu item', () {
      final pr = PurchaseRequisitionSummary.fromJson(
        eprocurementListItem(itemsCount: 1),
      );

      expect(pr.itemCountLabel, '1 item');
    });

    test('itemCountLabel memakai bentuk jamak untuk lebih dari satu', () {
      final pr = PurchaseRequisitionSummary.fromJson(
        eprocurementListItem(itemsCount: 8),
      );

      expect(pr.itemCountLabel, '8 items');
    });

    test('menolak baris tanpa id — PR tanpa identitas tidak bisa dibuka', () {
      final json = eprocurementListItem()..remove('id');

      expect(
        () => PurchaseRequisitionSummary.fromJson(json),
        throwsA(isA<FormatException>()),
      );
    });

    test('menolak baris yang tanggalnya tidak bisa diurai', () {
      final json = eprocurementListItem(prDate: '0000-00-00');

      expect(
        () => PurchaseRequisitionSummary.fromJson(json),
        throwsA(isA<FormatException>()),
      );
    });
  });

  group('PurchaseRequisition.fromJson', () {
    test('membawa seluruh field ringkasan seperti versi daftar', () {
      final pr = PurchaseRequisition.fromJson(eprocurementDetail());

      expect(pr.id, 3);
      expect(pr.prNumber, 'PR/HSE/26-08/01');
      expect(pr.totalEstimatedAmount, 6900000);
      expect(pr.status.code, 'pending_finance');
    });

    test('memetakan field yang hanya ada di detail', () {
      final pr = PurchaseRequisition.fromJson(eprocurementDetail());

      expect(pr.department, 'HSE');
      expect(pr.requiredDate, DateTime(2026, 9, 3));
      expect(pr.priority, 'normal');
      expect(pr.paperRef, isNull);
      expect(pr.submittedAt, isNotNull);
      expect(pr.approvedAt, isNull);
      expect(pr.attachmentsCount, 3);
    });

    test('memetakan item beserta harga total dari server', () {
      final pr = PurchaseRequisition.fromJson(eprocurementDetail());
      final first = pr.items.first;

      expect(pr.items, hasLength(2));
      expect(first.lineNumber, 1);
      expect(first.kind, PrItemKind.service);
      expect(first.quantity, 1);
      expect(first.uom, 'set');
      expect(first.unitPrice, 3000000);
      expect(first.totalPrice, 3000000);
      expect(first.glAccount, '513110');
      expect(first.segment, 'SVC - MAINT');
    });

    test('nomor baris item dipakai apa adanya, boleh meloncat', () {
      final pr = PurchaseRequisition.fromJson(eprocurementDetail());

      expect(pr.items.map((i) => i.lineNumber).toList(), [1, 3]);
    });

    test('memetakan lampiran beserta ukuran dan tautannya', () {
      final pr = PurchaseRequisition.fromJson(eprocurementDetail());
      final attachment = pr.attachments.single;

      expect(attachment.id, 2);
      expect(attachment.isLink, isFalse);
      expect(attachment.label, 'Attachment perbaikan excavator.pdf');
      expect(attachment.sizeLabel, '389.57 KB');
      expect(attachment.url, isNotEmpty);
    });

    test('memetakan tahap approval beserta pelaku dan waktunya', () {
      final pr = PurchaseRequisition.fromJson(eprocurementDetail());

      expect(pr.approvalProgress, hasLength(3));
      expect(pr.approvalProgress[0].state, ApprovalState.approved);
      expect(pr.approvalProgress[0].approver, 'Habib Twindy Lubis');
      expect(pr.approvalProgress[0].actedAt, isNotNull);
      expect(pr.approvalProgress[1].state, ApprovalState.waiting);
      expect(pr.approvalProgress[1].approver, isNull);
      expect(pr.approvalProgress[2].state, ApprovalState.pending);
    });

    test('memetakan progress dokumen beserta nomor dokumennya', () {
      final pr = PurchaseRequisition.fromJson(eprocurementDetail());

      expect(pr.documentProgress[0].state, DocumentState.inProgress);
      expect(pr.documentProgress[1].state, DocumentState.notStarted);
      expect(pr.documentProgress[2].state, DocumentState.done);
      expect(pr.documentProgress[2].numbers, ['BIIE/26-08-003']);
      expect(pr.documentProgress[2].count, 1);
    });

    test('state yang tidak dikenal jatuh ke keadaan paling aman', () {
      final pr = PurchaseRequisition.fromJson(
        eprocurementDetail(
          approvalProgress: [
            {'level': 1, 'label': 'HOD', 'state': 'entah', 'state_label': ''},
          ],
          documentProgress: [
            {'code': 'pr_approval', 'label': 'PR Approval', 'state': 'entah'},
          ],
        ),
      );

      expect(pr.approvalProgress.single.state, ApprovalState.pending);
      expect(pr.documentProgress.single.state, DocumentState.notStarted);
    });

    test('alasan penolakan dibawa apa adanya bila terisi', () {
      final pr = PurchaseRequisition.fromJson(
        eprocurementDetail(rejectionReason: 'Anggaran belum tersedia'),
      );

      expect(pr.rejectionReason, 'Anggaran belum tersedia');
    });
  });
}
