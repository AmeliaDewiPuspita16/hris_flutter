import 'package:flutter/material.dart';

import '../../../../../../core/theme/app_colors.dart';

///
/// 1. [onWaiting] — baru diajukan, tim EST belum menindaklanjuti.
/// 2. [waitApprovalHosd] — tim EST sudah menyusun rencana kerja, menunggu
///    Head of Dept menyetujuinya. Belum bisa dibuka detailnya.
/// 3. [maintenancePlan] — rencana kerja sudah disetujui & tampil ke
///    requester (tombol hijau "Maintenance Plan" di web membuka rincian
///    working method & material/tools).
/// 4. [waitVerifyUser] — pekerjaan sudah selesai dikerjakan, menunggu
///    requester memverifikasi lewat laporan lengkap ("Show Details" di web,
///    di mobile jadi layar detail native — lihat EstRequestDetailScreen).
/// 5. [completed] — requester sudah memverifikasi. Sama seperti IT Request,
///    requester wajib kasih rating 1–5 bintang dulu sebelum bisa mengajukan
///    request baru (lihat [EstRequestFeedbackBanner]).
enum EstRequestStatus {
  onWaiting,
  waitApprovalHod,
  maintenancePlan,
  waitVerifyUser,
  completed;

  String get label => switch (this) {
        EstRequestStatus.onWaiting => 'On Waiting',
        EstRequestStatus.waitApprovalHod => 'Wait Approval HOD',
        EstRequestStatus.maintenancePlan => 'Maintenance Plan',
        EstRequestStatus.waitVerifyUser => 'Wait Verify User',
        EstRequestStatus.completed => 'Selesai',
      };

  Color get color => switch (this) {
        EstRequestStatus.onWaiting => AppColors.pending,
        EstRequestStatus.waitApprovalHod => AppColors.accent,
        EstRequestStatus.maintenancePlan => AppColors.present,
        EstRequestStatus.waitVerifyUser => AppColors.rejected,
        EstRequestStatus.completed => AppColors.primaryMid,
      };

  Color get background => switch (this) {
        EstRequestStatus.onWaiting => AppColors.pendingBg,
        EstRequestStatus.waitApprovalHod => AppColors.accentBg,
        EstRequestStatus.maintenancePlan => AppColors.presentBg,
        EstRequestStatus.waitVerifyUser => AppColors.rejectedBg,
        EstRequestStatus.completed => AppColors.primaryLight,
      };

  /// True kalau baris ini bisa diketuk untuk membuka detail — [onWaiting]
  /// dan [waitApprovalHosd] belum punya apa-apa untuk ditampilkan.
  bool get isTappable =>
      this == EstRequestStatus.maintenancePlan ||
      this == EstRequestStatus.waitVerifyUser ||
      this == EstRequestStatus.completed;
}
