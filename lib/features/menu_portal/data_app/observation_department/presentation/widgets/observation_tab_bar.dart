import 'package:flutter/material.dart';

import '../../../../../../core/theme/app_colors.dart';
import '../../../../../../core/theme/app_text_styles.dart';

/// Segmented pill tab bar layar Observation. Gayanya sama dengan
/// `IndentTabBar`; hanya dua tab, jadi pill dibagi rata selebar layar.
class ObservationTabBar extends StatelessWidget {
  const ObservationTabBar({
    super.key,
    required this.labels,
    required this.activeIndex,
    required this.onChanged,
    this.badgeCounts = const {},
  });

  final List<String> labels;
  final int activeIndex;
  final ValueChanged<int> onChanged;

  /// Badge merah per index tab (mis. jumlah observasi open). Tidak tampil
  /// kalau 0 atau tidak diisi.
  final Map<int, int> badgeCounts;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      // 42 pill + ruang bawah untuk bayangan pill aktif.
      height: 48,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(
          children: [
            for (var index = 0; index < labels.length; index++) ...[
              if (index > 0) const SizedBox(width: 8),
              Expanded(child: _pill(index)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _pill(int index) {
    final active = index == activeIndex;
    final badge = badgeCounts[index];

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
            Flexible(
              child: Text(
                labels[index],
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: AppTextStyles.fontFamily,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: active ? Colors.white : AppColors.text,
                ),
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
  }
}
