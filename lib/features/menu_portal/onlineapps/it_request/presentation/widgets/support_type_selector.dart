import 'package:flutter/material.dart';

import '../../../../../../core/theme/app_colors.dart';
import '../../../../../../core/theme/app_text_styles.dart';
import '../../domain/support_type.dart';

/// Segmented control "Support type" (Request / Repair / Return) gaya pill:
/// container abu membungkus ketiga opsi, yang terpilih jadi pill hijau tua
/// dengan teks putih — opsi lain transparan dengan teks abu.
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
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: AppColors.neutralBg, // abu muda (0xFFEDEDE7)
        borderRadius: BorderRadius.circular(9),
      ),
      child: Row(
        children: [
          for (final type in SupportType.values)
            Expanded(
              child: _Segment(
                label: type.label,
                active: value == type,
                onTap: () => onChanged(type),
              ),
            ),
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
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 7),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: active ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(7),
        ),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontFamily: AppTextStyles.fontFamily,
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: active ? Colors.white : AppColors.textMid,
          ),
        ),
      ),
    );
  }
}