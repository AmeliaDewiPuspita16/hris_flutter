import 'package:material_ui/material_ui.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../domain/duration_type.dart';

/// Pilihan durasi (Full Day / Half Day) di tab Ajukan.
///
/// Pilihan aktif sengaja memakai warna muda (tint) + centang, bukan isi hijau
/// penuh, supaya tidak terbaca sebagai tombol utama seperti Submit Request.
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
        Text('Duration', style: AppTextStyles.label),
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
                      color: active ? AppColors.primaryLight : AppColors.card,
                      borderRadius: BorderRadius.circular(9),
                      border: Border.all(
                        color: active ? AppColors.primaryText : AppColors.border,
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (active) ...[
                          Icon(Icons.check_rounded, size: 14, color: AppColors.primaryText),
                          const SizedBox(width: 5),
                        ],
                        Text(
                          type.label,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: active ? FontWeight.w700 : FontWeight.w600,
                            color: active ? AppColors.primaryText : AppColors.textMuted,
                          ),
                        ),
                      ],
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
