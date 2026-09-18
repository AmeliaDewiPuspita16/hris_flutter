import 'package:flutter/material.dart';

import '../../../../../../core/theme/app_colors.dart';
import '../../../../../../core/theme/app_text_styles.dart';
import '../../domain/support_type.dart';

/// Segmented control "Support type" (Request / Repair / Return) —
/// semua opsi kelihatan sekaligus tanpa perlu dibuka.
class SupportTypeSelector extends StatelessWidget {
  const SupportTypeSelector({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final SupportType? value;
  final ValueChanged<SupportType> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          for (final type in SupportType.values) ...[
            if (type != SupportType.values.first)
              Container(width: 1, height: 22, color: AppColors.border),
            Expanded(
              child: _Segment(
                label: type.label,
                active: value == type,
                onTap: () => onChanged(type),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Segment extends StatelessWidget {
  const _Segment({
    required this.label,
    required this.active,
    required this.onTap,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 11),
        alignment: Alignment.center,
        color: active ? AppColors.primary : Colors.transparent,
        child: Text(
          label,
          style: TextStyle(
            fontFamily: AppTextStyles.fontFamily,
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: active ? Colors.white : AppColors.textMid,
          ),
        ),
      ),
    );
  }
}