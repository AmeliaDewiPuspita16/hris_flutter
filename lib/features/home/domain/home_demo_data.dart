import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../pengajuan/domain/leave_type.dart';
import '../../shared/domain/role.dart';
import 'activity_entry.dart';
import 'attendance_status.dart';
import 'quota_balance.dart';

/// Data contoh untuk halaman Beranda.
///
/// Dikumpulkan di satu tempat supaya gampang ditukar begitu API-nya siap —
/// widget-widget Beranda tidak perlu diubah.
class HomeDemoData {
  HomeDemoData._();

  static const todayAttendance = AttendanceStatus(
    shiftLabel: 'Office Hours',
    shiftTime: '08:00–17:00',
    location: 'Plant 2 · Gate A',
    clockInTime: '06:52',
    workedDuration: '6h 08m worked',
  );

  /// Kartu saldo. Dua kartu pertama punya kuota sehingga tampil berdampingan
  /// dengan progress bar; kartu ketiga tanpa kuota, jadi melebar penuh.
  ///
  /// Kartu ketiga berbeda per role: yang berhak lembur melihat off in lieu,
  /// selain itu cuti pengganti.
  static List<QuotaBalance> quotaBalancesFor(Role role) => [
        const QuotaBalance(
          label: 'Annual Leave',
          value: 7.5,
          total: 12,
          caption: '/ 12 days',
        ),
        const QuotaBalance(
          label: 'Medical Check',
          value: 2.4,
          total: 5,
          caption: 'of 5.0 M',
        ),
        if (LeaveTypeX.showPersonalLembur(role))
          const QuotaBalance(
            label: 'Off in Lieu',
            value: 2,
            caption: 'days',
            note: '1 day expires 30 Sep',
          )
        else
          const QuotaBalance(
            label: 'Replacement Leave',
            value: 3,
            caption: 'days',
            note: '1 day expires 31 Dec',
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
