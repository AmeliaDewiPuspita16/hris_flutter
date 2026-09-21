import 'approval_step.dart';
import 'document_stage.dart';
import '../../../../../core/utils/json_value.dart';
import 'pr_attachment.dart';
import 'pr_line_item.dart';
import 'purchase_requisition_summary.dart';

/// Satu PR lengkap, dari `GET /api/portal/apps/eprocurement/{id}`.
///
/// Mewarisi [PurchaseRequisitionSummary] karena respons detail memang
/// ringkasan yang sama ditambah rinciannya — dengan begitu layar detail bisa
/// menampilkan kepala halaman dari ringkasan yang sudah ada di daftar sambil
/// menunggu rinciannya datang.
class PurchaseRequisition extends PurchaseRequisitionSummary {
  const PurchaseRequisition({
    required super.id,
    required super.prNumber,
    required super.prDate,
    required super.section,
    required super.requestor,
    required super.purpose,
    required super.itemsCount,
    required super.totalEstimatedAmount,
    required super.currency,
    required super.status,
    required this.department,
    required this.attachmentsCount,
    this.requiredDate,
    this.priority,
    this.paperRef,
    this.revisionNotes,
    this.rejectionReason,
    this.submittedAt,
    this.approvedAt,
    this.items = const [],
    this.attachments = const [],
    this.approvalProgress = const [],
    this.documentProgress = const [],
  });

  final String department;
  final int attachmentsCount;

  /// Tanggal barang/jasa dibutuhkan. Boleh kosong.
  final DateTime? requiredDate;

  final String? priority;

  /// Nomor dokumen kertas pendamping, bila ada.
  final String? paperRef;

  /// Terisi saat PR dikembalikan untuk diperbaiki.
  final String? revisionNotes;

  /// Terisi saat PR ditolak.
  final String? rejectionReason;

  final DateTime? submittedAt;
  final DateTime? approvedAt;

  final List<PrLineItem> items;
  final List<PrAttachment> attachments;
  final List<ApprovalStep> approvalProgress;
  final List<DocumentStage> documentProgress;

  factory PurchaseRequisition.fromJson(Map<String, dynamic> json) {
    // Field yang sama dengan daftar diurai sekali saja, di satu tempat.
    final base = PurchaseRequisitionSummary.fromJson(json);

    return PurchaseRequisition(
      id: base.id,
      prNumber: base.prNumber,
      prDate: base.prDate,
      section: base.section,
      requestor: base.requestor,
      purpose: base.purpose,
      itemsCount: base.itemsCount,
      totalEstimatedAmount: base.totalEstimatedAmount,
      currency: base.currency,
      status: base.status,
      department: '${json['department'] ?? ''}',
      attachmentsCount: intOr(json['attachments_count'], 0),
      requiredDate: dateOrNull(json['required_date']),
      priority: textOrNull(json['priority']),
      paperRef: textOrNull(json['paper_ref']),
      revisionNotes: textOrNull(json['revision_notes']),
      rejectionReason: textOrNull(json['rejection_reason']),
      submittedAt: dateOrNull(json['submitted_at']),
      approvedAt: dateOrNull(json['approved_at']),
      items: _mapList(json['items'], PrLineItem.fromJson),
      attachments: _mapList(json['attachments'], PrAttachment.fromJson),
      approvalProgress: _mapList(json['approval_progress'], ApprovalStep.fromJson),
      documentProgress: _mapList(json['document_progress'], DocumentStage.fromJson),
    );
  }
}

List<T> _mapList<T>(dynamic value, T Function(Map<String, dynamic>) map) =>
    (value as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(map)
        .toList(growable: false);
