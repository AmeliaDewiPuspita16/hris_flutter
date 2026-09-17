import 'package:flutter/material.dart';

import '../../../../../../core/theme/app_colors.dart';
import '../../../../../../core/theme/app_text_styles.dart';

/// Grup checkbox singkat yang muncul di bawah opsi "What do you need?"
/// bertipe checkbox — mis. Laptop/PC/Printer/Mouse — dan juga dipakai untuk
/// "Equipment / Access Needed" pada sub-form New employee account creation.
class NeedCheckboxGroup extends StatelessWidget {
  const NeedCheckboxGroup({
    super.key,
    required this.labels,
    required this.selected,
    required this.onChanged,
  });

  final List<String> labels;
  final Set<String> selected;
  final ValueChanged<Set<String>> onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 16,
      runSpacing: 10,
      children: [
        for (final label in labels)
          InkWell(
            onTap: () {
              final next = Set<String>.from(selected);
              if (!next.remove(label)) next.add(label);
              onChanged(next);
            },
            borderRadius: BorderRadius.circular(6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  selected.contains(label)
                      ? Icons.check_box
                      : Icons.check_box_outline_blank,
                  size: 18,
                  color: selected.contains(label) ? AppColors.primary : AppColors.textMuted,
                ),
                const SizedBox(width: 6),
                Text(label, style: AppTextStyles.body.copyWith(fontSize: 13)),
              ],
            ),
          ),
      ],
    );
  }
}