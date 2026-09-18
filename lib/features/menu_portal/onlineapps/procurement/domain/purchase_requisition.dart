import 'approval_step.dart';
import 'document_stage.dart';
import 'pr_attachment.dart';
import 'pr_line_item.dart';
import 'pr_status.dart';

/// Satu Purchase Requisition beserta seluruh isi layar detailnya.
class PurchaseRequisition {
  const PurchaseRequisition({
    required this.id,
    required this.prNumber,
    required this.date,
    required this.department,
    required this.section,
    required this.requestor,
    required this.requiredDate,
    required this.purpose,
    required this.status,
    required this.items,
    this.attachments = const [],
    this.approvalSteps = const [],
    this.documentStages = const [],
  });

  final String id;

  /// Ex: "PR/EVD/26-09/10".
  final String prNumber;

  final DateTime date;
  final String department;
  final String section;
  final String requestor;
  final DateTime requiredDate;
  final String purpose;
  final PrStatus status;
  final List<PrLineItem> items;
  final List<PrAttachment> attachments;
  final List<ApprovalStep> approvalSteps;
  final List<DocumentStage> documentStages;

  int get itemCount => items.length;

  /// Est. Total di kepala layar detail. Dihitung dari [items] supaya angka di
  /// kartu daftar dan jumlah di tabel item tidak mungkin berselisih.
  int get estimatedTotal =>
      items.fold(0, (total, item) => total + item.subtotal);

  /// Ex: "1 item", "8 items" — persis badge jumlah item di web.
  String get itemCountLabel => itemCount == 1 ? '1 item' : '$itemCount items';

  /// Apakah PR ini cocok dengan kata kunci di kolom "Cari".
  ///
  /// Mencari di nomor PR, nama requestor, dan purpose — tiga kolom yang
  /// dibaca orang saat mencari PR tertentu. Query kosong cocok dengan semua.
  bool matchesQuery(String query) {
    final keyword = query.trim().toLowerCase();
    if (keyword.isEmpty) return true;

    return prNumber.toLowerCase().contains(keyword) ||
        requestor.toLowerCase().contains(keyword) ||
        purpose.toLowerCase().contains(keyword);
  }
}
