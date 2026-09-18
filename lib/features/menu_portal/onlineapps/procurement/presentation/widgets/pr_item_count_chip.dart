import 'package:flutter/material.dart';

import '../../../../../../core/theme/app_colors.dart';
import '../../../../../../core/theme/app_text_styles.dart';

/// Badge jumlah item ("1 item" / "8 items"), mengikuti badge ungu di kolom
/// ITEMS versi web. Dipakai di kartu daftar dan judul bagian ITEMS di detail.
class PrItemCountChip extends StatelessWidget {
  const PrItemCountChip({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.violetBg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontFamily: AppTextStyles.fontFamily,
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: AppColors.violet,
        ),
      ),
    );
  }
}
