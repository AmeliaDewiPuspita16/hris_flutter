import 'package:flutter/material.dart';

import '../../../../../../../core/theme/app_colors.dart';
import '../../../../../../../core/theme/app_text_styles.dart';

/// Segmented pill tab bar untuk tampilan IT Request tim IT — (Form IT &
/// Media / List Request / Report), dibuat scroll horizontal supaya muat di
/// layar sempit.
class ItRequestTabBar extends StatelessWidget {
  const ItRequestTabBar({
    super.key,
    required this.labels,
    required this.activeIndex,
    required this.onChanged,
    this.badgeCounts = const {},
  });

  final List<String> labels;
  final int activeIndex;
  final ValueChanged<int> onChanged;

  /// Badge merah opsional per index, misalnya jumlah item yang butuh
  /// perhatian pada tab tersebut.
  final Map<int, int> badgeCounts;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: labels.length,
        separatorBuilder: (_, __) => const SizedBox(width: 6),
        itemBuilder: (context, index) {
          final active = index == activeIndex;
          final badge = badgeCounts[index];

          return InkWell(
            onTap: () => onChanged(index),
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
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
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
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