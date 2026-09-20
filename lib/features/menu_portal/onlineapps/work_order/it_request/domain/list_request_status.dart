import 'package:flutter/material.dart';

import '../../../../../../core/theme/app_colors.dart';

/// Status di tab "List Request"
enum ListRequestStatus {
  onWaiting,
  onProgress,
  waitVerify,
  done,
  closed;

  String get label => switch (this) {
        ListRequestStatus.onWaiting => 'On Waiting',
        ListRequestStatus.onProgress => 'On Progress',
        ListRequestStatus.waitVerify => 'Wait Verify',
        ListRequestStatus.done => 'Done',
        ListRequestStatus.closed => 'Closed',
      };

  Color get color => switch (this) {
        ListRequestStatus.onWaiting => AppColors.pending,
        ListRequestStatus.onProgress => AppColors.present,
        ListRequestStatus.waitVerify => AppColors.accent,
        ListRequestStatus.done => AppColors.primaryMid,
        ListRequestStatus.closed => AppColors.textMuted,
      };

  Color get background => switch (this) {
        ListRequestStatus.onWaiting => AppColors.pendingBg,
        ListRequestStatus.onProgress => AppColors.presentBg,
        ListRequestStatus.waitVerify => AppColors.accentBg,
        ListRequestStatus.done => AppColors.primaryLight,
        ListRequestStatus.closed => AppColors.neutralBg,
      };
}