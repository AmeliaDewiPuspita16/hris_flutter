import '../../../../../../core/utils/json_value.dart';
import 'est_json.dart';

/// Satu langkah di timeline `progress` pada `GET /est_work_order/{id}`:
/// Request Submitted -> HOD Approval -> Maintenance Plan by EST -> Section
/// Head Approval -> Work Finished -> Verified by Requester.
class EstProgressStep {
  const EstProgressStep({
    required this.state,
    required this.key,
    required this.label,
    this.by,
    this.at,
    this.note,
  });

  static const stateDone = 'done';
  static const stateCurrent = 'current';
  static const statePending = 'pending';
  static const stateRejected = 'rejected';
  static const stateSkipped = 'skipped';

  /// `done`, `current`, `pending`, `rejected`, atau `skipped`. Nilai di luar
  /// itu diperlakukan seperti `pending` oleh tampilan.
  final String state;

  /// Penanda tetap langkahnya, mis. `plan_approval`.
  final String key;
  final String label;

  /// Siapa yang menyelesaikan langkah ini; null bila belum / tidak tercatat.
  final String? by;

  /// Waktu langkah selesai, siap tampil (mis. `23 Oct 2026 · 16:11`). Null
  /// bila belum, atau memang tidak disimpan — `hod_approval` selalu null.
  final String? at;
  final String? note;

  factory EstProgressStep.fromJson(Map<String, dynamic> json) {
    final at = textOrNull(json['at']);

    return EstProgressStep(
      state: textOrNull(json['state']) ?? statePending,
      key: textOrNull(json['key']) ?? '',
      label: textOrNull(json['label']) ?? '-',
      by: textOrNull(json['by']),
      at: at == null ? null : estDateTime(at),
      note: textOrNull(json['note']),
    );
  }
}
