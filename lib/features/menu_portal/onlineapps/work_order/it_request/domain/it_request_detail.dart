import '../../../../../../core/utils/json_value.dart';
import 'code_label.dart';
import 'it_request_handling.dart';
import 'it_request_item.dart';
import 'it_request_new_employee.dart';

/// Satu request IT/Media lengkap, dari
/// `GET /api/portal/apps/it_request/{id}`.
///
/// Mewarisi [ItRequestItem] karena respons detail memang ringkasan yang sama
/// ditambah rinciannya — dengan begitu layar detail bisa menampilkan kepala
/// layar dari item yang sudah ada di daftar sambil menunggu rinciannya
/// datang. Pola sama dengan `PurchaseRequisition` di EProcurement.
class ItRequestDetail extends ItRequestItem {
  const ItRequestDetail({
    required super.id,
    required super.type,
    required super.supportType,
    required super.category,
    required super.description,
    required super.approval,
    required super.checking,
    required super.status,
    required super.createdAt,
    super.rating,
    super.imageUrl,
    super.requester,
    super.isMine,
    super.canRate,
    this.needs = const [],
    this.newEmployee,
    this.specifiedApplication,
    this.specifiedUsername,
    this.specifiedOther,
    this.handling,
    this.approvedAt,
    this.cancelReason,
    this.ratingComment,
  });

  /// Rincian "What do you need?" saat kategorinya punya sub-pilihan, ex.
  /// checklist hardware yang diminta.
  final List<CodeLabel> needs;

  final ItRequestNewEmployee? newEmployee;

  /// Isian text bebas saat kategorinya berupa satu field spesifikasi, ex.
  /// nama aplikasi yang ingin di-install.
  final String? specifiedApplication;
  final String? specifiedUsername;
  final String? specifiedOther;

  final ItRequestHandling? handling;
  final DateTime? approvedAt;
  final String? cancelReason;
  final String? ratingComment;

  factory ItRequestDetail.fromJson(Map<String, dynamic> json) {
    // Field yang sama dengan daftar diurai sekali saja, di satu tempat.
    final base = ItRequestItem.fromJson(json);
    final specified = json['specified'];

    return ItRequestDetail(
      id: base.id,
      type: base.type,
      supportType: base.supportType,
      category: base.category,
      description: base.description,
      approval: base.approval,
      checking: base.checking,
      status: base.status,
      createdAt: base.createdAt,
      rating: base.rating,
      imageUrl: base.imageUrl,
      requester: base.requester,
      isMine: base.isMine,
      canRate: base.canRate,
      needs: (json['needs'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(CodeLabel.fromJson)
          .toList(growable: false),
      newEmployee: ItRequestNewEmployee.fromJsonOrNull(json['new_employee']),
      specifiedApplication: specified is Map
          ? textOrNull(specified['application'])
          : null,
      specifiedUsername:
          specified is Map ? textOrNull(specified['username']) : null,
      specifiedOther: specified is Map ? textOrNull(specified['other']) : null,
      handling: ItRequestHandling.fromJsonOrNull(json['handling']),
      approvedAt: dateOrNull(json['approved_at']),
      cancelReason: textOrNull(json['cancel_reason']),
      ratingComment: textOrNull(json['rating_comment']),
    );
  }
}
