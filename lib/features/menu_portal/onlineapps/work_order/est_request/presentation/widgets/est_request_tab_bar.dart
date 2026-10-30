import 'package:flutter/material.dart';

import '../../../../../../../core/theme/app_colors.dart';
import '../../../../../../../core/theme/app_text_styles.dart';

/// Deret pill tab EST Request (All Request / Approve HOD) dengan ikon di
/// kiri label, dibuat scroll horizontal supaya muat di layar sempit. Tab
/// aktif hijau tua berbayang; yang lain putih bergaris tepi. Gayanya sama
/// dengan `ItRequestTabBar` dan `IndentTabBar`.
class EstRequestTabBar extends StatelessWidget {
  const EstRequestTabBar({
    super.key,
    required this.labels,
    this.icons = const [],
    required this.activeIndex,
    required this.onChanged,
    this.badgeCounts = const {},
  });

  final List<String> labels;

  /// Ikon per tab, sejajar dengan [labels]. Kosong = tanpa ikon.
  final List<IconData> icons;
  final int activeIndex;
  final ValueChanged<int> onChanged;

  /// Badge merah opsional per index, misalnya jumlah rencana kerja yang
  /// belum diputuskan pada tab "Approve HOD".
  final Map<int, int> badgeCounts;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      // 42 pill + ruang bawah untuk bayangan pill aktif.
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.only(bottom: 6),
        itemCount: labels.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final active = index == activeIndex;
          final badge = badgeCounts[index];
          final icon = index < icons.length ? icons[index] : null;

          return InkWell(
            onTap: () => onChanged(index),
            borderRadius: BorderRadius.circular(22),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: active ? AppColors.primary : AppColors.card,
                borderRadius: BorderRadius.circular(22),
                border: active ? null : Border.all(color: AppColors.border),
                boxShadow: active
                    ? [
                        BoxShadow(
                          color: AppColors.primaryText.withValues(alpha: 0.25),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : null,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[
                    Icon(
                      icon,
                      size: 16,
                      color: active ? Colors.white : AppColors.primaryMidText,
                    ),
                    const SizedBox(width: 6),
                  ],
                  Text(
                    labels[index],
                    style: TextStyle(
                      fontFamily: AppTextStyles.fontFamily,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: active ? Colors.white : AppColors.text,
                    ),
                  ),
                  if (badge != null && badge > 0) ...[
                    const SizedBox(width: 5),
                    Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(
                        color: AppColors.badge,
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
