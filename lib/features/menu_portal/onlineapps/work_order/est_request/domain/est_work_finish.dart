import '../../../../../../core/utils/json_value.dart';
import 'est_json.dart';

/// Laporan pekerjaan selesai, dari `finish` di `GET /est_work_order/{id}`.
///
/// Null di [EstRequestDetail.finish] selama pekerjaan belum selesai
/// dikerjakan.
class EstWorkFinish {
  const EstWorkFinish({
    required this.dateStart,
    required this.dateEnd,
    required this.workBy,
    this.imageUrl,
  });

  /// Tanggal siap tampil, mis. `22 Oct 2026`.
  final String dateStart;
  final String dateEnd;

  /// Nama pelaksana lapangan.
  final String workBy;

  /// Foto hasil pekerjaan; null kalau tidak dilampirkan.
  final String? imageUrl;

  factory EstWorkFinish.fromJson(Map<String, dynamic> json) {
    return EstWorkFinish(
      dateStart: estDate(json['date_start']),
      dateEnd: estDate(json['date_end']),
      workBy: textOrNull(json['work_by']) ?? '-',
      imageUrl: textOrNull(json['image_url']),
    );
  }
}
