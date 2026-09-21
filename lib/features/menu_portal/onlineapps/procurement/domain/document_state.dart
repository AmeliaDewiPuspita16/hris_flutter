import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';

/// Keadaan satu tahap di `document_progress` (PR Approval, Vendor Tally,
/// Purchase Order, Goods Receipt).
enum DocumentState {
  done,
  inProgress,
  notStarted,
  rejected;

  /// Kode tak dikenal jatuh ke [notStarted] — sama alasannya dengan
  /// [ApprovalState.fromCode]: lebih baik mengaku belum mulai daripada
  /// mengaku selesai.
  static DocumentState fromCode(String code) => switch (code) {
        'done' => DocumentState.done,
        'in_progress' => DocumentState.inProgress,
        'rejected' => DocumentState.rejected,
        _ => DocumentState.notStarted,
      };

  Color get color => switch (this) {
        DocumentState.done => AppColors.present,
        DocumentState.inProgress => AppColors.accent,
        DocumentState.rejected => AppColors.rejected,
        DocumentState.notStarted => AppColors.neutral,
      };

  Color get background => switch (this) {
        DocumentState.done => AppColors.presentBg,
        DocumentState.inProgress => AppColors.accentBg,
        DocumentState.rejected => AppColors.rejectedBg,
        DocumentState.notStarted => AppColors.neutralBg,
      };

  bool get isFilled => this != DocumentState.notStarted;
}
