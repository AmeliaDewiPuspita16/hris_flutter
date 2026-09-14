import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../pengajuan/domain/leave_type.dart';
import '../../shared/domain/role.dart';
import 'activity_entry.dart';
import 'quota_balance.dart';

/// Data contoh untuk halaman Beranda.
///
/// Dikumpulkan di satu tempat supaya gampang ditukar begitu API-nya siap —
/// widget-widget Beranda tidak perlu diubah.
class HomeDemoData {
  HomeDemoData._();

  /// Kartu saldo berbeda per role: lembur hanya untuk yang berhak,
  /// selain itu ditampilkan cuti pengganti.
  static List<QuotaBalance> quotaBalancesFor(Role role) => [
        const QuotaBalance(
          label: 'Cuti Tahunan',
          value: 8,
          total: 12,
          unit: 'Hari',
          color: AppColors.primaryMid,
          background: AppColors.primaryLight,
        ),
        if (LeaveTypeX.showPersonalLembur(role))
          const QuotaBalance(
            label: 'Saldo Lembur',
            value: 14.5,
            unit: 'Jam',
            color: AppColors.violet,
            background: AppColors.violetBg,
          )
        else
          const QuotaBalance(
            label: 'Cuti Pengganti',
            value: 3,
            total: 5,
            unit: 'Hari',
            color: AppColors.teal,
            background: AppColors.tealBg,
          ),
        const QuotaBalance(
          label: 'Cek Kesehatan',
          value: 1,
          total: 1,
          unit: 'Kali',
          color: AppColors.pending,
          background: AppColors.pendingBg,
        ),
      ];

  static const recentActivities = <ActivityEntry>[
    ActivityEntry(
      icon: Icons.check_circle_outline,
      title: 'Cuti Tahunan Disetujui',
      description: '17–19 Jul 2025 · 3 hari',
      time: '2 jam lalu',
      color: AppColors.present,
      background: AppColors.presentBg,
    ),
    ActivityEntry(
      icon: Icons.hourglass_bottom_outlined,
      title: 'Lembur Menunggu',
      description: '28 Jul · 18:30–20:45 WIB',
      time: 'Kemarin',
      color: AppColors.pending,
      background: AppColors.pendingBg,
    ),
    ActivityEntry(
      icon: Icons.receipt_long_outlined,
      title: 'Slip Gaji Juli Tersedia',
      description: 'Rp 12.500.000',
      time: '1 hari lalu',
      color: AppColors.accent,
      background: AppColors.accentBg,
    ),
  ];
}
