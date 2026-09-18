import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';

/// Status satu Purchase Requisition, mengikuti tahap approval di web
/// EProcurement.
///
/// Versi web memberi tiap tahap warna sendiri-sendiri. Di layar HP badge-nya
/// jauh lebih kecil, jadi warnanya disederhanakan jadi tiga arti saja —
/// masih menunggu / disetujui / ditolak — sementara tahapannya tetap terbaca
/// dari [label]. Rincian per tahap tetap bisa dipilih lewat chip filter di
/// halaman daftar.
enum PrStatus {
  pendingHod,
  pendingUnderReview,
  pendingDgm,
  pendingFinance,
  pendingGm,
  prApproved,
  rejected;

  String get label => switch (this) {
        PrStatus.pendingHod => 'Pending HOD',
        PrStatus.pendingUnderReview => 'Pending Under Review',
        PrStatus.pendingDgm => 'Pending DGM',
        PrStatus.pendingFinance => 'Pending Finance Manager',
        PrStatus.pendingGm => 'Pending GM',
        PrStatus.prApproved => 'PR Approved',
        PrStatus.rejected => 'Rejected',
      };

  /// Label pendek untuk chip filter — "Pending Finance Manager" terlalu
  /// panjang untuk deret chip yang muat beberapa sekaligus di layar.
  String get shortLabel => switch (this) {
        PrStatus.pendingHod => 'HOD',
        PrStatus.pendingUnderReview => 'Under Review',
        PrStatus.pendingDgm => 'DGM',
        PrStatus.pendingFinance => 'Finance',
        PrStatus.pendingGm => 'GM',
        PrStatus.prApproved => 'Approved',
        PrStatus.rejected => 'Rejected',
      };

  /// True selama PR masih berjalan di rantai approval.
  bool get isPending => switch (this) {
        PrStatus.prApproved || PrStatus.rejected => false,
        _ => true,
      };

  Color get color => switch (this) {
        PrStatus.prApproved => AppColors.present,
        PrStatus.rejected => AppColors.rejected,
        _ => AppColors.pending,
      };

  Color get background => switch (this) {
        PrStatus.prApproved => AppColors.presentBg,
        PrStatus.rejected => AppColors.rejectedBg,
        _ => AppColors.pendingBg,
      };
}
