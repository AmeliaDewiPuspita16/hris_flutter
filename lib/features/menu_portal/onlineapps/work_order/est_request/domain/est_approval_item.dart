import '../../../../../../core/utils/json_value.dart';

/// Satu request EST dari department HOD yang menunggu keputusan, dari
/// `GET /api/portal/apps/est_work_order/approvals`.
///
/// Sengaja model terpisah dari [EstRequestItem] (daftar All Request yang
/// masih data demo): bentuknya mengikuti respons server apa adanya, dan
/// antrean ini belum membawa rencana kerja — status `waiting_hod` berarti
/// HOD menyetujui REQUEST-nya, sebelum tim EST menyusun rencana.
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
      date: _formatDate(json['created_at']),
      imageUrl: textOrNull(json['image_url']),
    );
  }

  static const _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  /// `2026-08-31T16:27:14+08:00` -> `31 Aug 2026`.
  ///
  /// Hanya 10 karakter pertama (yyyy-MM-dd) yang dibaca, JANGAN di-parse
  /// penuh lalu `toLocal()`: zona waktu server (+08:00) bisa beda dengan
  /// perangkat, dan request yang dibuat malam hari bisa bergeser ke
  /// tanggal lain.
  static String _formatDate(Object? raw) {
    final text = '${raw ?? ''}';
    if (text.length < 10) return text;

    final date = DateTime.tryParse(text.substring(0, 10));
    if (date == null) return text;

    return '${date.day} ${_months[date.month - 1]} ${date.year}';
  }
}
