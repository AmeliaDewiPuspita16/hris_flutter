import 'package:flutter/material.dart';

import '../../../../../../core/theme/app_colors.dart';
import '../../../../../../core/theme/app_text_styles.dart';

/// Badge "With Driver" (hijau) / "No Driver" (ungu). Dipakai kartu
/// Supervisor Approval; kartu Pending Vehicle Assignment masih punya
/// salinan privatnya sendiri dan boleh dialihkan ke widget ini.
class IndentDriverBadge extends StatelessWidget {
  const IndentDriverBadge({super.key, required this.withDriver});

  final bool withDriver;

  @override
  Widget build(BuildContext context) {
    final color = withDriver ? AppColors.present : AppColors.violet;
    final background = withDriver ? AppColors.presentBg : AppColors.violetBg;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        withDriver ? 'With Driver' : 'No Driver',
        style: TextStyle(
          fontFamily: AppTextStyles.fontFamily,
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}
