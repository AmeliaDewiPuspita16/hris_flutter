import 'package:flutter/material.dart';

import '../../../../../../core/theme/app_colors.dart';
import '../../../../../../core/theme/app_text_styles.dart';

/// Keadaan kosong untuk layar Observation Department: ikon abu-abu polos
/// (tanpa latar), judul, dan keterangan.
/// Dipakai saat belum ada data, atau saat pencarian tidak menemukan hasil.
/// Ikon bawaan berupa kotak masuk; layar boleh menggantinya lewat [icon].
class ObservationEmptyView extends StatelessWidget {
  const ObservationEmptyView({
    super.key,
    required this.title,
    required this.message,
    this.icon = Icons.inbox_outlined,
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
          Icon(icon, size: 44, color: AppColors.textMuted),
          const SizedBox(height: 16),
          Text(
            title,
            textAlign: TextAlign.center,
            style: AppTextStyles.body.copyWith(
              fontSize: 14,
              fontWeight: FontWeight.w600,
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
