import '../../../../../../core/utils/json_value.dart';
import 'it_request_type.dart';

/// Satu permintaan dari department HOD yang menunggu keputusan
/// (approve/reject), dari `GET /api/portal/apps/it_request/approvals`.
class ApproveRequestItem {
  const ApproveRequestItem({
    required this.id,
    required this.requesterName,
    required this.department,
    required this.description,
    this.supportType,
  });

  final int id;
  final String requesterName;
  final String department;
  final String description;

  /// Jenis dukungan seperti kolom Support Type di web, mis.
  /// `IT (PERMINTAAN)` atau `Media (PERMINTAAN)`. Null bila tidak diketahui.
  final String? supportType;

  /// Melempar [FormatException] bila `id` tidak terbaca — tanpa id,
  /// keputusan approve/reject tidak bisa dikirim.
  factory ApproveRequestItem.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    if (id is! int) {
      throw const FormatException(
          'Respons approval IT Request tidak memuat id');
    }

    final requester = json['requester'] is Map<String, dynamic>
        ? json['requester'] as Map<String, dynamic>
        : const <String, dynamic>{};
    final type = ItRequestType.fromCode('${json['type'] ?? ''}');
    final support = textOrNull(json['support_type']);

    return ApproveRequestItem(
      id: id,
      requesterName: '${requester['name'] ?? ''}',
      department: '${requester['department'] ?? ''}',
      description: '${json['description'] ?? ''}',
      supportType: support == null ? type.label : '${type.label} ($support)',
    );
  }
}
