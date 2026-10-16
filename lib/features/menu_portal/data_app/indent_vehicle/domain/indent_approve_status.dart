import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';

/// kolom "Approve" di tabel List of User Request — keputusan atasan,
/// dibaca dari field 'approval_hod' milik API:
///
/// | approval_hod | arti                 | nilai di sini |
/// |--------------|----------------------|---------------|
/// | 0            | belum diproses HOD   | [onWaiting]   |
/// | 1            | di-approve HOD       | [approved]    |
/// | 2            | di-reject HOD        | [rejected]    |
enum IndentApproveStatus {
  onWaiting,
  approved,
  rejected;

  String get label => switch (this) {
        IndentApproveStatus.onWaiting => 'On Waiting',
        IndentApproveStatus.approved => 'Approved',
        IndentApproveStatus.rejected => 'Rejected',
      };

  Color get color => switch (this) {
        IndentApproveStatus.onWaiting => AppColors.pending,
        IndentApproveStatus.approved => AppColors.present,
        IndentApproveStatus.rejected => AppColors.rejected,
      };

  Color get background => switch (this) {
        IndentApproveStatus.onWaiting => AppColors.pendingBg,
        IndentApproveStatus.approved => AppColors.presentBg,
        IndentApproveStatus.rejected => AppColors.rejectedBg,
      };
}
