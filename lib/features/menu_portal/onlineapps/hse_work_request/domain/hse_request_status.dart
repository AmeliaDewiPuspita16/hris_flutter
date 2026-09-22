import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/widgets/status_badge.dart';

/// Status permit HSE Work Request. (All Status, On Waiting, On Progress, Done, Reject)
/// HSE punya alur acknowledge + approval terpisah sebelum jadi Done.
enum HseRequestStatus { onWaiting, onProgress, done, reject }

extension HseRequestStatusX on HseRequestStatus {
  String get label => switch (this) {
        HseRequestStatus.onWaiting => 'On Waiting',
        HseRequestStatus.onProgress => 'On Progress',
        HseRequestStatus.done => 'Done',
        HseRequestStatus.reject => 'Reject',
      };

  /// Dipakai [StatusBadge] supaya warnanya konsisten dengan status lain di
  /// aplikasi (mis. approval cuti) — bukan bikin skema warna sendiri.
  AppStatus get appStatus => switch (this) {
        HseRequestStatus.onWaiting => AppStatus.pending,
        HseRequestStatus.onProgress => AppStatus.onProgress,
        HseRequestStatus.done => AppStatus.present,
        HseRequestStatus.reject => AppStatus.rejected,
      };

  /// Warna solid per status — dipakai [HseStatusTabs] supaya filter yang
  /// aktif ikut berwarna sesuai statusnya, bukan selalu hijau primary.
  /// Mengikuti token warna yang sama dengan [appStatus]/[StatusBadge]:
  /// pending → kuning, accent (dipakai juga untuk status "in progress" di
  /// EstRequestStatus) → biru, present → hijau, rejected → merah.
  Color get color => switch (this) {
        HseRequestStatus.onWaiting => AppColors.pending,
        HseRequestStatus.onProgress => AppColors.inProgress,
        HseRequestStatus.done => AppColors.present,
        HseRequestStatus.reject => AppColors.rejected,
      };

  /// Versi latar pudar dari [color], dipasangkan sebagai `selectedColor`
  /// chip filter.
  Color get background => switch (this) {
        HseRequestStatus.onWaiting => AppColors.pendingBg,
        HseRequestStatus.onProgress => AppColors.inProgressBg,
        HseRequestStatus.done => AppColors.presentBg,
        HseRequestStatus.reject => AppColors.rejectedBg,
      };

  static HseRequestStatus fromApi(String? value) => switch (value) {
        'on_progress' || 'On Progress' => HseRequestStatus.onProgress,
        'done' || 'Done' => HseRequestStatus.done,
        'reject' || 'Reject' => HseRequestStatus.reject,
        _ => HseRequestStatus.onWaiting,
      };
}
