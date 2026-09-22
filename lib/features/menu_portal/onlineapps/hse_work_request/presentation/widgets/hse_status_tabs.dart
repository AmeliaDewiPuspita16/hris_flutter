import 'package:flutter/material.dart';

import '../../../../../../../core/theme/app_colors.dart';
import '../../../../../../../core/theme/app_text_styles.dart';
import '../../domain/hse_request_status.dart';

/// Filter status HSE Work Request.
///
class HseStatusTabs extends StatelessWidget {
  const HseStatusTabs({super.key, required this.selected, required this.onChanged});

  /// Null berarti "All".
  final HseRequestStatus? selected;
  final ValueChanged<HseRequestStatus?> onChanged;

  static const _all = <HseRequestStatus?>[
    null,
    HseRequestStatus.onWaiting,
    HseRequestStatus.onProgress,
    HseRequestStatus.done,
    HseRequestStatus.reject,
  ];

  String _labelFor(HseRequestStatus? status) => status?.label ?? 'Semua';

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _all.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final status = _all[index];
          final isSelected = status == selected;

          return ChoiceChip(
            label: Text(_labelFor(status)),
            selected: isSelected,
            onSelected: (_) => onChanged(status),
            labelStyle: AppTextStyles.caption.copyWith(
              fontWeight: FontWeight.w700,
              color: isSelected ? Colors.white : AppColors.textMid,
            ),
            backgroundColor: Colors.white,
            selectedColor: AppColors.primary,
            side: BorderSide(color: isSelected ? AppColors.primary : AppColors.border),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
            visualDensity: VisualDensity.compact,
            showCheckmark: false,
          );
        },
      ),
    );
  }
}
