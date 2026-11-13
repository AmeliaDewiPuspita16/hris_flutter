import 'package:flutter/material.dart';

import '../../../../../../../core/theme/app_colors.dart';
import '../../../../../../../core/theme/app_text_styles.dart';

/// Horizontally scrolling single-select chips (filters).
class OpnameChipRow extends StatelessWidget {
  const OpnameChipRow({
    super.key,
    required this.labels,
    required this.selectedIndex,
    required this.onChanged,
    this.soft = false,
  });

  final List<String> labels;
  final int selectedIndex;
  final ValueChanged<int> onChanged;

  /// Soft = the selected chip is tinted instead of filled.
  final bool soft;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (var i = 0; i < labels.length; i++)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _Chip(
                label: labels[i],
                selected: i == selectedIndex,
                soft: soft,
                onTap: () => onChanged(i),
              ),
            ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.selected,
    required this.soft,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final bool soft;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bg = selected
        ? (soft ? AppColors.primaryLight : AppColors.primary)
        : AppColors.card;
    final fg = selected
        ? (soft ? AppColors.primaryText : Colors.white)
        : AppColors.textMid;

    return Material(
      color: bg,
      shape: StadiumBorder(
        side: BorderSide(
          color: selected ? AppColors.primaryText : AppColors.border,
          width: selected && soft ? 1.5 : 1,
        ),
      ),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
          child: Text(
            label,
            style: AppTextStyles.label.copyWith(
              color: fg,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ),
      ),
    );
  }
}
