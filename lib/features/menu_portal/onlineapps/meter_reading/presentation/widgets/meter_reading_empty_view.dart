import 'package:flutter/material.dart';

import '../../../../../../core/theme/app_colors.dart';
import '../../../../../../core/theme/app_text_styles.dart';

/// Daftar kosong. Tiga keadaan yang berbeda:
///  * ada filter/pencarian aktif → "tidak ada yang cocok" + tombol reset;
///  * filter "Not recorded" aktif dan hasilnya kosong → semua sudah dicatat
///    (kabar baik, bukan galat);
///  * memang belum ada meter.
class MeterReadingEmptyView extends StatelessWidget {
  const MeterReadingEmptyView({
    super.key,
    required this.hasActiveFilter,
    required this.onReset,
    this.allRecorded = false,
  });

  final bool hasActiveFilter;
  final VoidCallback onReset;

  /// True bila yang sedang dilihat adalah "Not recorded" dan tidak ada sisa.
  final bool allRecorded;

  @override
  Widget build(BuildContext context) {
    final IconData icon;
    final Color iconColor;
    final Color circleColor;
    final String title;
    final String message;

    if (allRecorded) {
      icon = Icons.task_alt_rounded;
      iconColor = AppColors.present;
      circleColor = AppColors.presentBg;
      title = 'All meters recorded';
      message = 'Nothing is waiting for a reading this period. Nice work!';
    } else if (hasActiveFilter) {
      icon = Icons.search_off_rounded;
      iconColor = AppColors.textMuted;
      circleColor = AppColors.neutralBg;
      title = 'No meters found';
      message = 'Nothing matches your search or filters. Try a different keyword.';
    } else {
      icon = Icons.speed_rounded;
      iconColor = AppColors.textMuted;
      circleColor = AppColors.neutralBg;
      title = 'No meters yet';
      message = 'Meters assigned to you will show up here.';
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 48, 32, 24),
      child: Column(
        children: [
          Container(
            width: 84,
            height: 84,
            decoration: BoxDecoration(color: circleColor, shape: BoxShape.circle),
            child: Icon(icon, size: 40, color: iconColor),
          ),
          const SizedBox(height: 20),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: AppTextStyles.fontFamily,
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: AppColors.text,
            ),
          ),
          const SizedBox(height: 8),
          Text(message, textAlign: TextAlign.center, style: AppTextStyles.bodyMuted),
          if (hasActiveFilter) ...[
            const SizedBox(height: 18),
            OutlinedButton.icon(
              onPressed: onReset,
              icon: const Icon(Icons.filter_alt_off_outlined, size: 18),
              label: const Text('Reset filters'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primaryText,
                side: BorderSide(color: AppColors.border),
                minimumSize: const Size(0, 44),
                padding: const EdgeInsets.symmetric(horizontal: 18),
                textStyle: TextStyle(
                  fontFamily: AppTextStyles.fontFamily,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                ),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
