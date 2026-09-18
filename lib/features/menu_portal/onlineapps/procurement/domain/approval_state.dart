import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';

/// Keadaan satu tahap di `approval_progress`.
enum ApprovalState {
  approved,
  rejected,
  revision,
  waiting,
  pending;

  /// Kode tak dikenal jatuh ke [pending] — keadaan paling aman, karena
  /// menggambarkan "belum terjadi apa-apa" alih-alih mengaku sudah disetujui.
  static ApprovalState fromCode(String code) => switch (code) {
        'approved' => ApprovalState.approved,
        'rejected' => ApprovalState.rejected,
        'revision' => ApprovalState.revision,
        'waiting' => ApprovalState.waiting,
        _ => ApprovalState.pending,
      };

  Color get color => switch (this) {
        ApprovalState.approved => AppColors.present,
        ApprovalState.rejected => AppColors.rejected,
        ApprovalState.revision => AppColors.violet,
        ApprovalState.waiting => AppColors.accent,
        ApprovalState.pending => AppColors.neutral,
      };

  Color get background => switch (this) {
        ApprovalState.approved => AppColors.presentBg,
        ApprovalState.rejected => AppColors.rejectedBg,
        ApprovalState.revision => AppColors.violetBg,
        ApprovalState.waiting => AppColors.accentBg,
        ApprovalState.pending => AppColors.neutralBg,
      };

  /// Titik yang sudah tersentuh digambar padat; yang belum hanya lingkaran
  /// samar, supaya posisi PR terbaca tanpa membaca teksnya.
  bool get isFilled => this != ApprovalState.pending;
}
