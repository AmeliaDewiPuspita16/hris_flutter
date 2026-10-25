import '../../../../../../core/utils/json_value.dart';
import 'est_json.dart';

/// Satu request EST dari department HOD yang menunggu keputusan, dari
/// `GET /api/portal/apps/est_work_order/approvals`.
///
/// Sengaja model terpisah dari [EstRequestItem] (daftar All Request):
/// bentuknya mengikuti respons server apa adanya, dan antrean ini hanya
/// berisi request berstatus `waiting_hod` — HOD menyetujui REQUEST-nya,
/// sebelum tim EST menyusun rencana.
class EstApprovalItem {
  const EstApprovalItem({
    required this.id,
    required this.type,
    required this.location,
    required this.description,
    required this.requesterName,
    required this.department,
    required this.date,
    this.imageUrl,
  });

  final int id;

  /// Apa adanya dari server, mis. `Repair` atau `Project`.
  final String type;
  final String location;
  final String description;
  final String requesterName;
  final String department;

  /// Tanggal request siap tampil, mis. `31 Aug 2026`.
  final String date;

  /// URL foto lampiran; null kalau requester tidak melampirkan foto.
  final String? imageUrl;

  /// Melempar [FormatException] bila `id` tidak terbaca — tanpa id,
  /// keputusan approve/reject tidak bisa dikirim.
  factory EstApprovalItem.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    if (id is! int) {
      throw const FormatException('Respons approval EST tidak memuat id');
    }

    final requester = json['requester'] is Map<String, dynamic>
        ? json['requester'] as Map<String, dynamic>
        : const <String, dynamic>{};

    return EstApprovalItem(
      id: id,
      type: '${json['type'] ?? ''}',
      location: '${json['location'] ?? ''}',
      description: '${json['description'] ?? ''}',
      requesterName: '${requester['name'] ?? ''}',
      department: '${requester['department'] ?? ''}',
      date: estDate(json['created_at']),
      imageUrl: textOrNull(json['image_url']),
    );
  }
}
