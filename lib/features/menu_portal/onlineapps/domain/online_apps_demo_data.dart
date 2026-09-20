import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import 'online_app_item.dart';

/// Data daftar Online Apps.
///
/// Disusun sebagai function (bukan konstanta statis) karena tiap item butuh
/// [VoidCallback] dari pemanggil — beberapa perlu BuildContext untuk buka
/// modal atau halaman lain.
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
          department: 'HRGA Dept',
          color: AppColors.primary,
          background: AppColors.primaryLight,
          onTap: onInventory,
        ),
        OnlineAppItem(
          icon: Icons.speed_outlined,
          label: 'Meter Reading',
          department: 'EST Dept',
          color: AppColors.teal,
          background: AppColors.tealBg,
          onTap: onMeterReading,
        ),
        OnlineAppItem(
          icon: Icons.event_available_outlined,
          label: 'Reservation',
          department: 'Bintan Inti Executive Village',
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
          department: 'For Tenant Request',
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
          department: 'HSE Work Permit Request',
          color: AppColors.rejected,
          background: AppColors.rejectedBg,
          onTap: onHseWorkRequest,
        ),
      ];
}
