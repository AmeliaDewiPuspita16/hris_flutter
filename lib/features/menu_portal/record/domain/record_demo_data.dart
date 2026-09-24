import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import 'record_item.dart';

/// Data daftar Records.
///
/// Disusun sebagai function (bukan konstanta statis) karena tiap item butuh
/// [VoidCallback] dari pemanggil.
class RecordDemoData {
  RecordDemoData._();

  static List<RecordItem> items({
    required VoidCallback onCompanyProfile,
    required VoidCallback onContract,
    required VoidCallback onEngineeringDrawing,
    required VoidCallback onImsDocument,
    required VoidCallback onLicensePermitCertificate,
    required VoidCallback onNewsClipping,
    required VoidCallback onPhotoVideo,
  }) =>
      [
        RecordItem(
          icon: Icons.business_outlined,
          label: 'Company Profile',
          owners: const ['Nanda', 'Fadel'],
          color: AppColors.primaryMid,
          background: AppColors.primaryLight,
          onTap: onCompanyProfile,
        ),
        RecordItem(
          icon: Icons.description_outlined,
          label: 'Contract',
          owners: const ['Riza'],
          color: AppColors.itRequest,
          background: AppColors.itRequestBg,
          onTap: onContract,
        ),
        RecordItem(
          icon: Icons.architecture_outlined,
          label: 'Engineering Drawing',
          owners: const ['Yason', 'Tris'],
          color: AppColors.teal,
          background: AppColors.tealBg,
          onTap: onEngineeringDrawing,
        ),
        RecordItem(
          icon: Icons.fact_check_outlined,
          label: 'IMS Document',
          owners: const ['Fauzi'],
          color: AppColors.estRequest,
          background: AppColors.estRequestBg,
          onTap: onImsDocument,
        ),
        RecordItem(
          icon: Icons.workspace_premium_outlined,
          label: 'License, Permit and Certificate',
          owners: const ['Dava', 'Andang'],
          color: AppColors.accent,
          background: AppColors.accentBg,
          onTap: onLicensePermitCertificate,
        ),
        RecordItem(
          icon: Icons.newspaper_outlined,
          label: 'News Clipping',
          owners: const ['Admin CRS'],
          color: AppColors.violet,
          background: AppColors.violetBg,
          onTap: onNewsClipping,
        ),
        RecordItem(
          icon: Icons.perm_media_outlined,
          label: 'Photo & Video',
          owners: const ['Noval', 'Ari'],
          color: AppColors.primary,
          background: AppColors.primaryLight,
          onTap: onPhotoVideo,
        ),
      ];
}
