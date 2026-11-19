import 'package:flutter/material.dart';

import '../../../../../../core/theme/app_colors.dart';
import '../../../../../../core/theme/app_text_styles.dart';
import '../../domain/meter_reading_page.dart';

/// Ringkasan kemajuan pencatatan di atas daftar: "12 of 20 recorded" dengan
/// bilah progres. Jawaban atas pertanyaan pertama petugas — "berapa lagi
/// yang harus saya kerjakan?" — tanpa harus menghitung chip.
///
/// Angkanya dari `counts` server, jadi benar untuk seluruh meter walau baru
/// satu halaman yang termuat.
class MeterProgressSummary extends StatelessWidget {
  const MeterProgressSummary({super.key, required this.counts});

  final MeterReadingCounts counts;

  @override
  Widget build(BuildContext context) {
    final total = counts.all;
    if (total <= 0) return const SizedBox.shrink();

    final progress = (counts.recorded / total).clamp(0.0, 1.0);
    final done = counts.pending == 0;
    // primaryText, bukan primary: primary hijau tua nyaris hilang di tema gelap.
    final color = done ? AppColors.present : AppColors.primaryText;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        done ? 'All caught up' : 'This period',
                        style: TextStyle(
                          fontFamily: AppTextStyles.fontFamily,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8,
                          color: AppColors.textMuted,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: '${counts.recorded}',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                                color: color,
                              ),
                            ),
                            TextSpan(
                              text: ' of $total recorded',
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textMid,
                              ),
                            ),
                          ],
                        ),
                        style: TextStyle(fontFamily: AppTextStyles.fontFamily, height: 1.1),
                      ),
                    ],
                  ),
                ),
                if (!done)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.accentBg,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${counts.pending} to go',
                      style: TextStyle(
                        fontFamily: AppTextStyles.fontFamily,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.accent,
                      ),
                    ),
                  )
                else
                  Icon(Icons.check_circle_rounded, size: 28, color: AppColors.present),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: progress),
                duration: const Duration(milliseconds: 450),
                curve: Curves.easeOutCubic,
                builder: (_, v, __) => LinearProgressIndicator(
                  value: v,
                  minHeight: 8,
                  backgroundColor: AppColors.neutralBg,
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
