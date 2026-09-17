import 'package:flutter/material.dart';

import '../../../../../../core/theme/app_colors.dart';
import '../../../../../../core/theme/app_text_styles.dart';

/// Placeholder tab "Report" — sengaja dibiarkan kosong dulu di iterasi ini.
class ReportTabPlaceholder extends StatelessWidget {
  const ReportTabPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.bar_chart_outlined, size: 40, color: AppColors.textMuted),
            const SizedBox(height: 12),
            Text(
              'Report belum tersedia',
              style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              'Ringkasan & grafik permintaan akan tampil di sini.',
              style: AppTextStyles.caption,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
