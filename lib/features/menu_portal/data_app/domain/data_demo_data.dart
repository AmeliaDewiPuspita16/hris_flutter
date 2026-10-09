import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import 'data_item.dart';

/// Data daftar menu Data.
///
/// Disusun sebagai function (bukan konstanta statis) karena tiap item butuh
/// [VoidCallback] dari pemanggil
class DataDemoData {
  DataDemoData._();

  static List<DataItem> items({
    required VoidCallback onAwardRecognition,
    required VoidCallback onBudgetDepartment,
    required VoidCallback onCatalogKitchen,
    required VoidCallback onDailyWorker,
    required VoidCallback onDormitoryBie,
    required VoidCallback onEstProjectMonitoring,
    required VoidCallback onExportImport,
    required VoidCallback onFacility,
    required VoidCallback onFoodCost,
    required VoidCallback onGymMember,
    required VoidCallback onIndentVehicle,
    required VoidCallback onInfrastucture,
  }) =>
      [
        DataItem(
          icon: Icons.emoji_events_outlined,
          label: 'Award & Recognition',
          owners: const ['Riza'],
          color: AppColors.accent,
          background: AppColors.accentBg,
          onTap: onAwardRecognition,
        ),
        DataItem(
          icon: Icons.account_balance_wallet_outlined,
          label: 'Budget Department',
          owners: const ['Herbert'],
          color: AppColors.estRequest,
          background: AppColors.estRequestBg,
          onTap: onBudgetDepartment,
        ),
        DataItem(
          icon: Icons.kitchen_outlined,
          label: 'Catalog Kitchen',
          owners: const ['Irma'],
          color: AppColors.orange,
          background: AppColors.orangeBg,
          onTap: onCatalogKitchen,
        ),
        DataItem(
          icon: Icons.badge_outlined,
          label: 'Daily Worker',
          owners: const ['Afifah'],
          color: AppColors.itRequest,
          background: AppColors.itRequestBg,
          onTap: onDailyWorker,
        ),
        DataItem(
          icon: Icons.apartment_outlined,
          label: 'Dormitory BIE',
          owners: const ['Erick'],
          color: AppColors.violet,
          background: AppColors.violetBg,
          onTap: onDormitoryBie,
        ),
        DataItem(
          icon: Icons.engineering_outlined,
          label: 'EST Project Monitoring',
          owners: const ['Khoirul'],
          color: AppColors.teal,
          background: AppColors.tealBg,
          onTap: onEstProjectMonitoring,
        ),
        DataItem(
          icon: Icons.local_shipping_outlined,
          label: 'Export Import',
          owners: const ['Andang'],
          color: AppColors.primaryMid,
          background: AppColors.primaryLight,
          onTap: onExportImport,
        ),
        DataItem(
          icon: Icons.business_outlined,
          label: 'Facility',
          owners: const ['Nanda', 'Fadel'],
          color: AppColors.accent,
          background: AppColors.accentBg,
          onTap: onFacility,
        ),
        DataItem(
          icon: Icons.restaurant_outlined,
          label: 'Food Cost',
          owners: const ['Irma'],
          color: AppColors.orange,
          background: AppColors.orangeBg,
          onTap: onFoodCost,
        ),
        DataItem(
          icon: Icons.fitness_center_outlined,
          label: 'Gym Member',
          owners: const ['Erick'],
          color: AppColors.violet,
          background: AppColors.violetBg,
          onTap: onGymMember,
        ),
        DataItem(
          icon: Icons.directions_car_outlined,
          label: 'Indent Vehicle',
          owners: const ['Saragih'],
          color: AppColors.teal,
          background: AppColors.tealBg,
          onTap: onIndentVehicle,
        ),
        DataItem(
          icon: Icons.foundation_outlined,
          label: 'Infrastucture',
          owners: const ['Nanda', 'Fadel'],
          color: AppColors.primaryMid,
          background: AppColors.primaryLight,
          onTap: onInfrastucture,
        ),
      ];
}
