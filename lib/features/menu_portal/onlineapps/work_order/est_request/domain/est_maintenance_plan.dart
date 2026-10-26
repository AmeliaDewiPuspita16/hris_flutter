import '../../../../../../core/utils/json_value.dart';
import 'est_json.dart';

/// Rencana kerja yang disusun tim EST untuk satu request, dari
/// `maintenance_plan` di `GET /est_work_order/{id}`.
///
/// Null di [EstRequestDetail.plan] selama tim EST belum menyusunnya
/// (status `waiting_hod` dan `waiting`).
class EstMaintenancePlan {
  const EstMaintenancePlan({
    required this.workingMethod,
    required this.materialAndTools,
    required this.approvalLabel,
    this.workDurationDays,
    this.manPower,
    this.approvedBy,
    this.approvedAt,
  });

  /// Teks biasa — di server isinya HTML, sudah diubah oleh [estPlainText].
  final String workingMethod;
  final String materialAndTools;

  /// Lama pengerjaan dalam hari (satuan "hari" adalah asumsi dari data demo
  /// lama: `1 Day`; belum tertulis di dokumentasi API).
  final int? workDurationDays;
  final int? manPower;

  /// Section Head yang menyetujui rencana; null selama belum disetujui.
  final String? approvedBy;

  /// Tanggal persetujuan siap tampil; null selama belum disetujui.
  final String? approvedAt;

  /// Status approval rencana dari server, mis. `Wait Approval Section Head`
  /// atau `Approved by Agus Salim`.
  final String approvalLabel;

  String get durationLabel {
    final days = workDurationDays;
    if (days == null) return '-';
    return days == 1 ? '1 day' : '$days days';
  }

  factory EstMaintenancePlan.fromJson(Map<String, dynamic> json) {
    final approvedAt = textOrNull(json['approved_at']);

    return EstMaintenancePlan(
      workingMethod: estPlainText(json['working_method']) ?? '-',
      materialAndTools: estPlainText(json['material_and_tools']) ?? '-',
      workDurationDays: estOptionalInt(json['work_duration']),
      manPower: estOptionalInt(json['man_power']),
      approvedBy: textOrNull(json['approved_by']),
      approvedAt: approvedAt == null ? null : estDate(approvedAt),
      approvalLabel: textOrNull(json['approval_label']) ?? '-',
    );
  }
}
