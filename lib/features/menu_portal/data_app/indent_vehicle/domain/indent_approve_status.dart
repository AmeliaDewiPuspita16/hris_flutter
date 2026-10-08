import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';

/// kolom "Approve" di tabel List of User Request. Hanay 2 kemungkinan:
/// belum diputuskan atasan ('onWaiting') dan sudah disetujui ('approved')
enum IndentApproveStatus {
  onWaiting,
  approved;

  String get label => switch (this) {
        IndentApproveStatus.onWaiting => 'On Waiting',
        IndentApproveStatus.approved => 'Approved',
      };

  Color get color => switch (this) {
        IndentApproveStatus.onWaiting => AppColors.pending,
        IndentApproveStatus.approved => AppColors.present,
      };

  Color get background => switch (this) {
        IndentApproveStatus.onWaiting => AppColors.pendingBg,
        IndentApproveStatus.approved => AppColors.presentBg,
      };
}
