import 'package:flutter/material.dart';

import '../../../../../../../core/theme/app_colors.dart';
import '../../../../../../../core/theme/app_text_styles.dart';
import '../../../../../../../core/widgets/app_text_field.dart';
import 'field_label_row.dart';

/// Grup pilihan majemuk berbentuk chip, mis. "Type of Works" & "Personal
/// Protective Equipment".
///
/// Dipisah dari [HseChecklistGroup]: General Checklist isinya kalimat
/// panjang (cocok sebagai baris), sedangkan Type of Works/PPE isinya
/// istilah pendek (cocok sebagai chip yang lebih padat & cepat di-scan).
/// Set [onChanged] untuk mode isi; biarkan null untuk mode baca (detail).
class HseChoiceChipGroup extends StatelessWidget {
  const HseChoiceChipGroup({
    super.key,
    required this.title,
    required this.options,
    required this.selected,
    this.onChanged,
    this.otherController,
    this.readOnly = false,
    this.required = false,
  });

  final String title;
  final List<String> options;
  final Set<String> selected;
  final ValueChanged<String>? onChanged;
  final TextEditingController? otherController;
  final bool readOnly;
  final bool required;

  @override
  Widget build(BuildContext context) {
    if (readOnly) {
      final chosen = options.where(selected.contains).toList();
      final other = otherController?.text ?? '';
      if (chosen.isEmpty && other.isEmpty) return const SizedBox.shrink();

      return Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: AppTextStyles.sectionTitle),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final item in chosen) _ReadOnlyChip(label: item),
                if (other.isNotEmpty) _ReadOnlyChip(label: other),
              ],
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FieldLabelRow(label: title, required: required),
          const SizedBox(height: 4),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final option in options)
                FilterChip(
                  label: Text(option),
                  selected: selected.contains(option),
                  onSelected: (_) => onChanged?.call(option),
                  labelStyle: AppTextStyles.caption.copyWith(
                    fontWeight: FontWeight.w600,
                    color: selected.contains(option) ? Colors.white : AppColors.textMid,
                  ),
                  backgroundColor: Colors.white,
                  selectedColor: AppColors.primaryMid,
                  side: BorderSide(
                    color: selected.contains(option) ? AppColors.primaryMid : AppColors.border,
                  ),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  showCheckmark: false,
                ),
            ],
          ),
          if (otherController != null) ...[
            const SizedBox(height: 10),
            AppTextField(
              label: 'Lainnya (opsional)',
              controller: otherController!,
              hint: 'Isi manual bila tidak ada di daftar di atas',
            ),
          ],
        ],
      ),
    );
  }
}

class _ReadOnlyChip extends StatelessWidget {
  const _ReadOnlyChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primaryMid),
      ),
    );
  }
}
