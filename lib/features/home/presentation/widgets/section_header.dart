import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

/// Judul section di Beranda, dengan tautan aksi opsional di sisi kanan.
class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    this.actionLabel,
    this.actionIcon,
    this.onActionTap,
  });

  final String title;
  final String? actionLabel;

  /// Ikon kecil di kanan label aksi, mis. panah pada "Request →".
  final IconData? actionIcon;

  final VoidCallback? onActionTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: AppTextStyles.sectionTitle),
          if (actionLabel != null)
            TextButton(
              onPressed: onActionTap,
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    actionLabel!,
                    style: const TextStyle(
                      fontFamily: AppTextStyles.fontFamily,
                      color: AppColors.primaryMid,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (actionIcon != null) ...[
                    const SizedBox(width: 4),
                    Icon(actionIcon, size: 13, color: AppColors.primaryMid),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }
}
