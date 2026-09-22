import 'package:flutter/material.dart';

import '../../../../../../../core/theme/app_colors.dart';
import '../../../../../../../core/theme/app_text_styles.dart';

/// Segmented pill tab bar untuk tampilan EST Request tim HOD —
/// (All Request / Approve HOD), sama polanya dengan [ItRequestTabBar] di
/// fitur IT Request. Dibuat scroll horizontal supaya muat di layar sempit
/// walau untuk dua tab ini biasanya belum perlu.
class EstRequestTabBar extends StatelessWidget {
  const EstRequestTabBar({
    super.key,
    required this.labels,
    required this.activeIndex,
    required this.onChanged,
    this.badgeCounts = const {},
  });

  final List<String> labels;
  final int activeIndex;
  final ValueChanged<int> onChanged;

  /// Badge merah opsional per index, misalnya jumlah rencana kerja yang
  /// belum diputuskan pada tab "Approve HOD".
  final Map<int, int> badgeCounts;

  @override
  Widget build(BuildContext context) {
    // Ukuran & padding disamakan dengan HseStatusTabs (height 36, chip lebih
    // ramping) — sebelumnya lebih besar (height 38, padding horizontal 14
    // tanpa padding vertikal). ListView tidak lagi punya padding horizontal
    // sendiri karena sekarang selalu ditaruh di dalam Padding(16) level
    // layar, sama seperti HseStatusTabs.
    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: labels.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final active = index == activeIndex;
          final badge = badgeCounts[index];

          return InkWell(
            onTap: () => onChanged(index),
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: active ? AppColors.primary : AppColors.card,
                borderRadius: BorderRadius.circular(20),
                border: active ? null : Border.all(color: AppColors.border),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    labels[index],
                    style: TextStyle(
                      fontFamily: AppTextStyles.fontFamily,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      color: active ? Colors.white : AppColors.textMid,
                    ),
                  ),
                  if (badge != null && badge > 0) ...[
                    const SizedBox(width: 5),
                    Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(
                        color: AppColors.rejected,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '$badge',
                        style: const TextStyle(
                          fontFamily: AppTextStyles.fontFamily,
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
