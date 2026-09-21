import 'package:flutter/material.dart';

import '../../../../../../../core/theme/app_colors.dart';
import '../../../../../../../core/theme/app_text_styles.dart';
import '../../domain/est_request_type.dart';

/// Segmented control "Type of request" (Repair / Project) gaya pill —
/// container abu membungkus kedua opsi, yang terpilih jadi pill solid warna
/// primary dengan teks putih, opsi lain transparan dengan teks abu.
class RequestTypeSelector extends StatelessWidget {
  const RequestTypeSelector({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final EstRequestType? value;
  final ValueChanged<EstRequestType> onChanged;

  IconData _iconFor(EstRequestType type) => switch (type) {
        EstRequestType.repair => Icons.build_outlined,
        EstRequestType.project => Icons.apartment_outlined,
      };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: AppColors.neutralBg,
        borderRadius: BorderRadius.circular(9),
      ),
      child: Row(
        children: [
          for (final type in EstRequestType.values)
            Expanded(
              child: _Segment(
                label: type.label,
                icon: _iconFor(type),
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
    required this.icon,
    required this.active,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 9),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: active ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(7),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 15,
              color: active ? Colors.white : AppColors.textMid,
            ),
            const SizedBox(width: 6),
            Text(
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
          ],
        ),
      ),
    );
  }
}
