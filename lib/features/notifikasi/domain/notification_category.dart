import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

/// Jenis notifikasi beserta lambang dan warnanya.
///
/// Sama polanya dengan AnnouncementTag: dibuat sebagai konstanta bernama
/// supaya satu jenis selalu tampil dengan ikon dan warna yang sama di
/// seluruh aplikasi, tanpa perlu ditulis ulang di tiap data.
class NotificationCategory {
  const NotificationCategory({
    required this.label,
    required this.icon,
    required this.color,
    required this.background,
  });

  final String label;
  final IconData icon;
  final Color color;
  final Color background;

  static const approval = NotificationCategory(
    label: 'Approval',
    icon: Icons.task_alt,
    color: AppColors.primary,
    background: AppColors.primaryLight,
  );

  static const payroll = NotificationCategory(
    label: 'Payroll',
    icon: Icons.receipt_long_outlined,
    color: AppColors.accent,
    background: AppColors.accentBg,
  );

  static const attendance = NotificationCategory(
    label: 'Attendance',
    icon: Icons.fingerprint,
    color: AppColors.present,
    background: AppColors.presentBg,
  );

  static const leave = NotificationCategory(
    label: 'Leave',
    icon: Icons.event_available_outlined,
    color: AppColors.teal,
    background: AppColors.tealBg,
  );

  static const announcement = NotificationCategory(
    label: 'Announcement',
    icon: Icons.campaign_outlined,
    color: AppColors.violet,
    background: AppColors.violetBg,
  );
}
