import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';

/// kolom "Status" di tabel List of User Request - posisi pemakaian
/// kendaraannya, dibaca dari field `status` milik API:
///
/// | status | arti                          | nilai di sini |
/// |--------|-------------------------------|---------------|
/// | 0      | menunggu                      | [onWaiting]   |
/// | 1      | disetujui admin / sedang jalan| [onProgress]  |
/// | 3      | selesai                       | [done]        |
/// | 5      | dibatalkan admin              | [cancelled]   |
///
/// sengaja dipisah dari 'IndentApproveStatus': keduanya dua kolom berbeda
/// dengan pilihan nilai berbeda, dan satu request bisa "Approved" tapi
/// sttausnya masih "On Waiting" (sudah disetujui, kendaraan belum jalan).
enum IndentProgressStatus {
  onWaiting,
  onProgress,
  done,
  cancelled;

  String get label => switch (this) {
        IndentProgressStatus.onWaiting => 'On Waiting',
        IndentProgressStatus.onProgress => 'On Progress',
        IndentProgressStatus.done => 'Done',
        IndentProgressStatus.cancelled => 'Cancelled',
      };

  Color get color => switch (this) {
        IndentProgressStatus.onWaiting => AppColors.pending,
        IndentProgressStatus.onProgress => AppColors.inProgress,
        IndentProgressStatus.done => AppColors.primaryMidText,
        IndentProgressStatus.cancelled => AppColors.rejected,
      };

  Color get background => switch (this) {
        IndentProgressStatus.onWaiting => AppColors.pendingBg,
        IndentProgressStatus.onProgress => AppColors.inProgressBg,
        IndentProgressStatus.done => AppColors.primaryLight,
        IndentProgressStatus.cancelled => AppColors.rejectedBg,
      };
}
