import 'package:material_ui/material_ui.dart';

import '../../../../../core/theme/app_colors.dart';

/// Status persetujuan bacaan: `pending`, `approved`, atau `rejected`.
///
/// Berbeda dari `MeterReadingState` (sudah/belum dicatat di periode aktif):
/// ini soal nasib bacaan itu SETELAH dicatat. Web belum menampilkannya;
/// di aplikasi, status ini yang menentukan apakah petugas masih bisa
/// mengedit (lewat `action` dari server).
///
/// Kode tak dikenal jatuh ke [pending] — pola sama dengan
/// `MeterReadingState.fromCode`.
enum MeterApprovalStatus {
  pending('pending', 'Pending'),
  approved('approved', 'Approved'),
  rejected('rejected', 'Rejected');

  const MeterApprovalStatus(this.code, this.label);

  final String code;
  final String label;

  static MeterApprovalStatus fromCode(String? code) =>
      switch (code?.toLowerCase()) {
        'approved' => MeterApprovalStatus.approved,
        'rejected' => MeterApprovalStatus.rejected,
        _ => MeterApprovalStatus.pending,
      };

  Color get color => switch (this) {
        MeterApprovalStatus.pending => AppColors.accent,
        MeterApprovalStatus.approved => AppColors.present,
        MeterApprovalStatus.rejected => AppColors.rejected,
      };

  Color get background => switch (this) {
        MeterApprovalStatus.pending => AppColors.accentBg,
        MeterApprovalStatus.approved => AppColors.presentBg,
        MeterApprovalStatus.rejected => AppColors.rejected.withValues(alpha: 0.10),
      };

  IconData get icon => switch (this) {
        MeterApprovalStatus.pending => Icons.schedule_rounded,
        MeterApprovalStatus.approved => Icons.verified_rounded,
        MeterApprovalStatus.rejected => Icons.cancel_rounded,
      };
}
