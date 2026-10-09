import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';

/// kolom "Status" di tabel List of User Request - posisi pemakaian
/// kendaraannya: belum jalan ('onWaiting'), sedang jalan ('onProgress'),
/// atau sudah selesai ('done').
///
/// sengaja dipisah dari 'IndentApproveStatus': keduanya dua kolom berbeda
/// dengan pilihan nilai berbeda, dan satu request bisa "Approved" tapi
/// sttausnya masih "On Waiting" (sudah disetujui, kendaraan belum jalan).
enum IndentProgressStatus {
  onWaiting,
  onProgress,
  done;

  String get label => switch (this) {
        IndentProgressStatus.onWaiting => 'On Waiting',
        IndentProgressStatus.onProgress => 'On Progress',
        IndentProgressStatus.done => 'Done',
      };

  Color get color => switch (this) {
        IndentProgressStatus.onWaiting => AppColors.pending,
        IndentProgressStatus.onProgress => AppColors.inProgress,
        IndentProgressStatus.done => AppColors.primaryMid,
      };

  Color get background => switch (this) {
        IndentProgressStatus.onWaiting => AppColors.pendingBg,
        IndentProgressStatus.onProgress => AppColors.inProgressBg,
        IndentProgressStatus.done => AppColors.primaryLight,
      };
}
