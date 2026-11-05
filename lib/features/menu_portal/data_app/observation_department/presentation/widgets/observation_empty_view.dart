import 'package:flutter/material.dart';

import '../../../../../../core/theme/app_colors.dart';
import '../../../../../../core/theme/app_text_styles.dart';

/// Keadaan kosong untuk layar Observation Department: lingkaran ikon
/// bernada [AppColors.accent] (warna tile menu Data), judul, dan keterangan.
/// Dipakai saat belum ada data, atau saat pencarian tidak menemukan hasil.
class ObservationEmptyView extends StatelessWidget {
  const ObservationEmptyView({
    super.key,
    required this.title,
    required this.message,
    this.icon = Icons.remove_red_eye_outlined,
  });

  final String title;
  final String message;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.accentBg,
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.accent.withValues(alpha: 0.25),
              ),
            ),
            child: Icon(icon, size: 30, color: AppColors.accent),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            textAlign: TextAlign.center,
            style: AppTextStyles.body.copyWith(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.text,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: AppTextStyles.caption.copyWith(height: 1.45),
          ),
        ],
      ),
    );
  }
}
