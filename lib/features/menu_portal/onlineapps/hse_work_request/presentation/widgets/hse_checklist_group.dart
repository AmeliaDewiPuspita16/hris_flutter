import 'package:flutter/material.dart';

import '../../../../../../../core/theme/app_colors.dart';
import '../../../../../../../core/theme/app_text_styles.dart';
import '../../../../../../../core/widgets/app_card.dart';
import '../../../../../../../core/widgets/app_text_field.dart';

/// Satu grup checklist bertitel, mis. "General Checklist".
///
/// Set [onChanged] & [otherController] untuk mode isi (form Add Request);
/// biarkan null untuk mode baca saja (layar detail) — item yang tidak
/// tercentang otomatis tidak ditampilkan sama sekali di mode baca
class HseChecklistGroup extends StatelessWidget {
  const HseChecklistGroup({
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
      final hasOther = otherController?.text.isNotEmpty ?? false;

      if (chosen.isEmpty && !hasOther) {
        return const SizedBox.shrink();
      }

      return Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: AppTextStyles.sectionTitle),
            const SizedBox(height: 8),
            AppCard(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              child: Column(
                children: [
                  for (final item in chosen) _ReadOnlyRow(label: item),
                  if (hasOther) _ReadOnlyRow(label: otherController!.text),
                ],
              ),
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
          RichText(
            text: TextSpan(
              style: AppTextStyles.sectionTitle,
              children: [
                TextSpan(text: title),
                if (required)
                  const TextSpan(
                      text: ' *', style: TextStyle(color: AppColors.rejected)),
              ],
            ),
          ),
          const SizedBox(height: 8),
          AppCard(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            child: Column(
              children: [
                for (final option in options)
                  _CheckRow(
                    label: option,
                    checked: selected.contains(option),
                    onTap: () => onChanged?.call(option),
                  ),
              ],
            ),
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

class _CheckRow extends StatelessWidget {
  const _CheckRow(
      {required this.label, required this.checked, required this.onTap});

  final String label;
  final bool checked;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              checked ? Icons.check_box : Icons.check_box_outline_blank,
              size: 20,
              color: checked ? AppColors.primary : AppColors.textMuted,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: AppTextStyles.body.copyWith(
                  color: checked ? AppColors.text : AppColors.textMid,
                  fontWeight: checked ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReadOnlyRow extends StatelessWidget {
  const _ReadOnlyRow({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle, size: 16, color: AppColors.present),
          const SizedBox(width: 8),
          Expanded(child: Text(label, style: AppTextStyles.body)),
        ],
      ),
    );
  }
}
