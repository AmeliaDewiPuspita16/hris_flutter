import 'package:flutter/material.dart';

import '../../../../../../../core/theme/app_colors.dart';
import '../../../../../../../core/theme/app_text_styles.dart';

/// Grup pilihan chip (multi-select) yang muncul di bawah opsi "What do you
/// need?" bertipe checkbox — mis. Laptop/PC/Printer/Mouse — dan juga
/// dipakai untuk "Equipment / Access needed" pada sub-form New employee
/// account creation.
class NeedChoiceChips extends StatelessWidget {
  const NeedChoiceChips({
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
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final label in labels)
          _Chip(
            label: label,
            active: selected.contains(label),
            onTap: () {
              final next = Set<String>.from(selected);
              if (!next.remove(label)) next.add(label);
              onChanged(next);
            },
          ),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.active, required this.onTap});

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: active ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: active ? AppColors.primary : AppColors.border,
            width: 1.2,
            ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min, 
          children: [
            // if (active) ...[
            //   const Icon(Icons.check, size: 13, color: Colors.white),
            //   const SizedBox(width: 6),
            // ],
            Text(
              label,
              style: TextStyle(
                fontFamily: AppTextStyles.fontFamily,
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: active ? Colors.white : AppColors.textMid,
              ),
            ),
          ],
        ),
      ),
    );
  }
}