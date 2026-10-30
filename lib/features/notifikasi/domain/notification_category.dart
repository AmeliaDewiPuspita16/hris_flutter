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

  @override
  bool operator ==(Object other) =>
      other is NotificationCategory && other.label == label;

  @override
  int get hashCode => label.hashCode;

  static NotificationCategory get approval => NotificationCategory(
    label: 'Approval',
    icon: Icons.task_alt,
    color: AppColors.primaryText,
    background: AppColors.primaryLight,
  );

  static NotificationCategory get payroll => NotificationCategory(
    label: 'Payroll',
    icon: Icons.receipt_long_outlined,
    color: AppColors.accent,
    background: AppColors.accentBg,
  );

  static NotificationCategory get attendance => NotificationCategory(
    label: 'Attendance',
    icon: Icons.fingerprint,
    color: AppColors.present,
    background: AppColors.presentBg,
  );

  static NotificationCategory get leave => NotificationCategory(
    label: 'Leave',
    icon: Icons.event_available_outlined,
    color: AppColors.teal,
    background: AppColors.tealBg,
  );

  static NotificationCategory get itRequest => NotificationCategory(
    label: 'IT request',
    icon: Icons.computer_outlined,
    color: AppColors.itRequest,
    background: AppColors.itRequestBg,
  );

  static NotificationCategory get estRequest => NotificationCategory(
    label: 'EST request',
    icon: Icons.home_repair_service_outlined,
    color: AppColors.estRequest,
    background: AppColors.estRequestBg,
  );

  static NotificationCategory get procurement => NotificationCategory(
    label: 'Procurement',
    icon: Icons.trending_up_outlined,
    color: AppColors.accent,
    background: AppColors.accentBg,
  );

  static NotificationCategory get indentVehicle => NotificationCategory(
    label: 'Indent vehicle',
    icon: Icons.directions_car_outlined,
    color: AppColors.orange,
    background: AppColors.orangeBg,
  );

  static NotificationCategory get announcement => NotificationCategory(
    label: 'Announcement',
    icon: Icons.campaign_outlined,
    color: AppColors.violet,
    background: AppColors.violetBg,
  );
}
