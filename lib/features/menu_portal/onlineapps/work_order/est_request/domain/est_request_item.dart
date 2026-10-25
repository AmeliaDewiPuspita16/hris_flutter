import '../../../../../../core/utils/json_value.dart';
import 'est_json.dart';
import 'est_maintenance_plan.dart';
import 'est_request_status.dart';
import 'est_work_detail.dart';

/// Satu baris di daftar "All Request" EST, dari
/// `GET /api/portal/apps/est_work_order`.
///
/// Bentuknya mengikuti respons server apa adanya. Hak aksi
/// ([canEdit], [canDelete], [canRate]) dihitung SERVER; aplikasi hanya
/// menampilkan tombol sesuai flag ini, tidak menghitung ulang sendiri.
class EstRequestItem {
  const EstRequestItem({
    required this.id,
    required this.type,
    required this.location,
    required this.description,
    required this.requesterName,
    required this.department,
    required this.date,
    required this.status,
    this.imageUrl,
    this.approvedBy,
    this.rejectReason,
    this.rating,
    this.isMine = false,
    this.canEdit = false,
    this.canDelete = false,
    this.canRate = false,
    this.plan,
    this.workDetail,
  });

  final int id;

  /// Apa adanya dari server: `Repair` atau `Project`.
  final String type;
  final String location;
  final String description;
  final String requesterName;
  final String department;

  /// Tanggal request siap tampil, mis. `21 Oct 2026`.
  final String date;
  final EstRequestStatus status;

  /// URL foto lampiran; null kalau requester tidak melampirkan foto.
  /// Catatan: server bisa mengirim `.heic`, yang tidak bisa ditampilkan di
  /// semua perangkat.
  final String? imageUrl;

  /// Nama HOD yang menyetujui; null selama masih `waiting_hod`.
  final String? approvedBy;

  /// Alasan penolakan; terisi hanya bila status `rejected` dan HOD mengisinya.
  final String? rejectReason;

  /// Bintang 1-5 dari requester; null kalau belum memberi rating.
  final int? rating;

  /// True kalau request ini milik user yang sedang login. Daftar ini berisi
  /// request SEMUA user.
  final bool isMine;

  final bool canEdit;
  final bool canDelete;

  /// True kalau requester boleh memverifikasi + memberi rating sekarang.
  final bool canRate;

  /// Rencana kerja dan laporan pekerjaan. Daftar tidak membawanya, jadi
  /// selalu null di sini; baru terisi dari layar detail
  /// (`GET /est_work_order/{id}`).
  final EstMaintenancePlan? plan;
  final EstWorkDetail? workDetail;

  /// Melempar [FormatException] bila `id` tidak terbaca — tanpa id, aksi
  /// apa pun pada request ini tidak bisa dikirim.
  factory EstRequestItem.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    if (id is! int) {
      throw const FormatException('Respons request EST tidak memuat id');
    }

    final requester = json['requester'] is Map<String, dynamic>
        ? json['requester'] as Map<String, dynamic>
        : const <String, dynamic>{};

    final rating = estOptionalInt(json['rating']);

    return EstRequestItem(
      id: id,
      type: '${json['type'] ?? ''}',
      location: '${json['location'] ?? ''}',
      description: '${json['description'] ?? ''}',
      requesterName: '${requester['name'] ?? ''}',
      department: '${requester['department'] ?? ''}',
      date: estDate(json['created_at']),
      status: EstRequestStatus.fromJson(json['status']),
      imageUrl: textOrNull(json['image_url']),
      approvedBy: textOrNull(json['approved_by']),
      rejectReason: textOrNull(json['reject_reason']),
      rating: rating != null && rating > 0 ? rating : null,
      isMine: json['is_mine'] == true,
      canEdit: json['can_edit'] == true,
      canDelete: json['can_delete'] == true,
      canRate: json['can_rate'] == true,
    );
  }
}
