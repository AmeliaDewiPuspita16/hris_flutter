import '../../../../../../core/utils/json_value.dart';
import 'est_maintenance_plan.dart';
import 'est_progress_step.dart';
import 'est_request_item.dart';
import 'est_work_finish.dart';

/// Hasil `GET /api/portal/apps/est_work_order/{id}`: field yang sama dengan
/// baris di daftar ([item]), ditambah rencana kerja, laporan selesai,
/// feedback requester, dan timeline progress.
///
/// ```json
/// { "data": { "id": 1175, ..., "maintenance_plan": {...}, "finish": {...},
///             "feedback": null, "progress": [...] } }
/// ```
class EstRequestDetail {
  const EstRequestDetail({
    required this.item,
    required this.progress,
    this.plan,
    this.finish,
    this.feedback,
  });

  /// Field dasar (termasuk flag `can_*`); terbaru dari server, jadi dipakai
  /// menggantikan baris di daftar begitu detail termuat.
  final EstRequestItem item;

  /// Null selama tim EST belum menyusun rencana.
  final EstMaintenancePlan? plan;

  /// Null selama pekerjaan belum selesai.
  final EstWorkFinish? finish;

  /// Catatan tertulis dari requester; null kalau belum ada.
  ///
  /// Bentuknya BELUM teramati (di contoh selalu `null`): dibaca sebagai teks
  /// biasa, atau objek dengan kunci `feedback` / `note` / `comment`.
  final String? feedback;

  final List<EstProgressStep> progress;

  /// Melempar [FormatException] bila `id` tidak terbaca.
  factory EstRequestDetail.fromJson(Map<String, dynamic> json) {
    final plan = json['maintenance_plan'];
    final finish = json['finish'];
    final progress = json['progress'];

    return EstRequestDetail(
      item: EstRequestItem.fromJson(json),
      plan: plan is Map<String, dynamic> ? EstMaintenancePlan.fromJson(plan) : null,
      finish: finish is Map<String, dynamic> ? EstWorkFinish.fromJson(finish) : null,
      feedback: _feedbackText(json['feedback']),
      progress: [
        if (progress is List)
          for (final step in progress.whereType<Map<String, dynamic>>())
            EstProgressStep.fromJson(step),
      ],
    );
  }

  static String? _feedbackText(Object? raw) {
    if (raw is String) return textOrNull(raw);
    if (raw is Map<String, dynamic>) {
      // Dokumentasi API: { rating, message, date }; kunci lain dipertahankan
      // untuk jaga-jaga.
      return textOrNull(
        raw['message'] ?? raw['feedback'] ?? raw['note'] ?? raw['comment'],
      );
    }
    return null;
  }
}
