import 'package:flutter/material.dart';

import '../../../../../../core/theme/app_colors.dart';
import '../../../../../../core/theme/app_text_styles.dart';
import '../../domain/hse_request_status.dart';

/// Filter status HSE Work Permit berbentuk pill yang bisa digulir
/// horizontal. Pill aktif hijau tua solid, sisanya putih bergaris tepi.
class HseStatusTabs extends StatelessWidget {
  const HseStatusTabs({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  /// Null berarti "Semua".
  final HseRequestStatus? selected;
  final ValueChanged<HseRequestStatus?> onChanged;

  static const _all = <HseRequestStatus?>[
    null,
    HseRequestStatus.onWaiting,
    HseRequestStatus.onProgress,
    HseRequestStatus.done,
    HseRequestStatus.reject,
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _all.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final status = _all[index];
          final active = status == selected;

          return Material(
            color: active ? AppColors.primary : AppColors.card,
            shape: StadiumBorder(
              side: active
                  ? BorderSide.none
                  : BorderSide(color: AppColors.border),
            ),
            child: InkWell(
              onTap: () => onChanged(status),
              customBorder: const StadiumBorder(),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: Center(
                  child: Text(
                    status?.label ?? 'Semua',
                    style: AppTextStyles.caption.copyWith(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: active ? Colors.white : AppColors.text,
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
