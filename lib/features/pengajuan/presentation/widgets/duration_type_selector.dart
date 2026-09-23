import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../domain/duration_type.dart';

/// Segmented control 3 pilihan durasi, dipakai tab Ajukan untuk jenis Izin.
class DurationTypeSelector extends StatelessWidget {
  const DurationTypeSelector({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final DurationType value;
  final ValueChanged<DurationType> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Durasi', style: AppTextStyles.label),
        const SizedBox(height: 8),
        Row(
          children: DurationType.values.map((type) {
            final active = value == type;
            final isLast = type == DurationType.values.last;

            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(right: isLast ? 0 : 8),
                child: InkWell(
                  onTap: () => onChanged(type),
                  borderRadius: BorderRadius.circular(9),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 9),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: active ? AppColors.primary : Colors.white,
                      borderRadius: BorderRadius.circular(9),
                      border: Border.all(
                        color: active ? AppColors.primary : AppColors.border,
                        width: 1.5,
                      ),
                    ),
                    child: Text(
                      type.label,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: active ? Colors.white : AppColors.textMuted,
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
