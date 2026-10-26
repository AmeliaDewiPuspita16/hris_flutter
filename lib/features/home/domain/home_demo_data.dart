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

  // Pengumuman tidak lagi punya data demo: daftarnya diambil dari
  // GET /api/portal/hr_announcement. Menampilkan pengumuman HR palsu saat
  // server gagal dijangkau lebih berbahaya daripada menampilkan keadaan
  // kosong atau pesan galat.

  /// Masih data contoh — belum ada API untuk aktivitas. Waktunya dibuat
  /// relatif terhadap [now] supaya label ("2 hours ago", dst.) selalu masuk
  /// akal. Sengaja lebih banyak dari batas tampil ([ActivityFeed.maxVisible])
  /// agar terlihat bahwa yang paling lama tidak ditampilkan.
  static List<ActivityEntry> recentActivities([DateTime? now]) {
    final t = now ?? DateTime.now();
    return [
      ActivityEntry(
        icon: Icons.check_circle_outline,
        title: 'Annual Leave Approved',
        description: '17–19 Jul 2025 · 3 days',
        occurredAt: t.subtract(const Duration(hours: 2)),
        color: AppColors.present,
        background: AppColors.presentBg,
      ),
      ActivityEntry(
        icon: Icons.hourglass_bottom_outlined,
        title: 'Overtime Pending',
        description: '28 Jul · 18:30–20:45 WIB',
        occurredAt: t.subtract(const Duration(days: 1)),
        color: AppColors.pending,
        background: AppColors.pendingBg,
      ),
      ActivityEntry(
        icon: Icons.receipt_long_outlined,
        title: 'July Payslip Available',
        description: 'Rp 12,500,000',
        occurredAt: t.subtract(const Duration(days: 2)),
        color: AppColors.accent,
        background: AppColors.accentBg,
      ),
      ActivityEntry(
        icon: Icons.event_available_outlined,
        title: 'Shift Schedule Updated',
        description: 'Week 31 · Morning shift',
        occurredAt: t.subtract(const Duration(days: 4)),
        color: AppColors.accent,
        background: AppColors.accentBg,
      ),
      ActivityEntry(
        icon: Icons.send_outlined,
        title: 'Leave Request Submitted',
        description: 'Replacement Leave · 1 day',
        occurredAt: t.subtract(const Duration(days: 9)),
        color: AppColors.pending,
        background: AppColors.pendingBg,
      ),
    ];
  }
}
