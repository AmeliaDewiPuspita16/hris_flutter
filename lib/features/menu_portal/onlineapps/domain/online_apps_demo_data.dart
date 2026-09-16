import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import 'online_app_item.dart';

/// Data contoh daftar Online Apps.
///
/// Disusun sebagai function (bukan konstanta statis) karena tiap item butuh
/// [VoidCallback] dari pemanggil — beberapa perlu BuildContext untuk buka
/// modal atau halaman lain. Sama seperti pola HomeDemoData.
class OnlineAppsDemoData {
  OnlineAppsDemoData._();

  static List<OnlineAppItem> items({
    required VoidCallback onInventory,
    required VoidCallback onMeterReading,
    required VoidCallback onReservation,
    required VoidCallback onProcurement,
    required VoidCallback onTenantFeedback,
    required VoidCallback onWorkOrder,
    required VoidCallback onHseWorkRequest,
  }) =>
      [
        OnlineAppItem(
          icon: Icons.inventory_2_outlined,
          label: 'Inventory',
          department: 'Logistics Dept',
          color: AppColors.primary,
          background: AppColors.primaryLight,
          onTap: onInventory,
        ),
        OnlineAppItem(
          icon: Icons.speed_outlined,
          label: 'Meter Reading',
          department: 'Utilities Dept',
          color: AppColors.teal,
          background: AppColors.tealBg,
          onTap: onMeterReading,
        ),
        OnlineAppItem(
          icon: Icons.event_available_outlined,
          label: 'Reservation',
          department: 'Admin Dept',
          color: AppColors.primaryMid,
          background: AppColors.primaryLight,
          onTap: onReservation,
        ),
        OnlineAppItem(
          icon: Icons.trending_up_outlined,
          label: 'Procurement Monitoring',
          department: 'Finance Dept',
          color: AppColors.accent,
          background: AppColors.accentBg,
          onTap: onProcurement,
        ),
        OnlineAppItem(
          icon: Icons.chat_bubble_outline,
          label: 'Tenant Feedback',
          department: 'Relations Dept',
          color: AppColors.violet,
          background: AppColors.violetBg,
          onTap: onTenantFeedback,
        ),
        OnlineAppItem(
          icon: Icons.build_outlined,
          label: 'Work Order',
          department: 'Engineering Dept',
          color: AppColors.primary,
          background: AppColors.primaryLight,
          onTap: onWorkOrder,
        ),
        OnlineAppItem(
          icon: Icons.health_and_safety_outlined,
          label: 'HSE Work Request',
          department: 'Safety Dept',
          color: AppColors.rejected,
          background: AppColors.rejectedBg,
          onTap: onHseWorkRequest,
        ),
      ];
}
