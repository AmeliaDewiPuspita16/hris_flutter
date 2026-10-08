import 'package:flutter/material.dart';

import '../../../../../../core/theme/app_colors.dart';
import '../../../../../../core/theme/app_text_styles.dart';

/// Segmented pill tab bar untuk layar Indent Vehicle. Polanya sama dengan
/// `EstRequestTabBar`; dibuat scroll horizontal karena label tab
/// ("Pending Vehicle Assignment") cukup panjang untuk layar sempit.
class IndentTabBar extends StatelessWidget {
  const IndentTabBar({
    super.key,
    required this.labels,
    required this.activeIndex,
    required this.onChanged,
    this.badgeCounts = const {},
  });

  final List<String> labels;
  final int activeIndex;
  final ValueChanged<int> onChanged;

  /// Badge merah opsional per index tab, mis. jumlah request yang masih
  /// menunggu keputusan. Tidak tampil kalau 0 atau tidak diisi.
  final Map<int, int> badgeCounts;

  @override
  Widget build(BuildContext context) {
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
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
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
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
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
