import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/widgets/status_badge.dart';

/// Baris badge nama owner/PIC - abu abu netral, lewat 'StatusBadge.custom'
/// supaya bentuknya (padding, radius 6, font) sama dengan tag lain di app
/// (tipe EST Request, kategori HSE, hierarchy dokumen IMS), bukan pill
/// bulat sendiri. DIpakai sebagai 'subtitle' [MenuListItem] dihalaman
/// Record dan Data
class OwnerBadgeRow extends StatelessWidget {
  const OwnerBadgeRow({
    super.key,
    required this.owners,
    this.color = AppColors.neutral,
    this.background = AppColors.neutralBg,
  });

  final List<String> owners;

  /// Warna badge — default abu-abu netral; halaman Records memakai warna
  /// kategorinya.
  final Color color;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      runSpacing: 4,
      children: [
        for (final owner in owners)
          StatusBadge.custom(
            label: owner,
            color: color,
            background: background,
          )
      ],
    );
  }
}
