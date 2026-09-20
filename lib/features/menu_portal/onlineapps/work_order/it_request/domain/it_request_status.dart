import 'package:flutter/material.dart';

import '../../../../../../core/theme/app_colors.dart';

/// Status siklus satu permintaan IT/Media, dari sudut pandang staff yang
/// mengajukan (bukan status internal tim IT yang lebih rinci di web).
enum ItRequestStatus {
  waitingHod,
  approved,
  onProgress,
  completed,
  rejected;

  String get label => switch (this) {
        ItRequestStatus.waitingHod => 'Wait Approval HOD',
        ItRequestStatus.approved => 'Approved',
        ItRequestStatus.onProgress => 'On Progress',
        ItRequestStatus.completed => 'Selesai',
        ItRequestStatus.rejected => 'Rejected',
      };

  Color get color => switch (this) {
        ItRequestStatus.waitingHod => AppColors.pending,
        ItRequestStatus.approved => AppColors.present,
        ItRequestStatus.onProgress => AppColors.teal,
        ItRequestStatus.completed => AppColors.present,
        ItRequestStatus.rejected => AppColors.rejected,
      };

  Color get background => switch (this) {
        ItRequestStatus.waitingHod => AppColors.pendingBg,
        ItRequestStatus.approved => AppColors.presentBg,
        ItRequestStatus.onProgress => AppColors.tealBg,
        ItRequestStatus.completed => AppColors.presentBg,
        ItRequestStatus.rejected => AppColors.rejectedBg,
      };
}
