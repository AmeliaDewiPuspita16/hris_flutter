import 'package:flutter/material.dart';

import '../../../../../../../core/theme/app_colors.dart';
import '../../../../../../../core/theme/app_text_styles.dart';
import '../../../../../../../core/widgets/app_text_field.dart';
import 'hse_checklist_group.dart';
import 'hse_page_chrome.dart';

/// Grup pilihan majemuk berbentuk chip dalam kartu [HseSectionCard], mis.
/// "Type of Works" & "Personal Protective Equipment".
///
/// Dipisah dari [HseChecklistGroup]: General Checklist isinya kalimat
/// panjang (cocok sebagai baris), sedangkan Type of Works/PPE isinya
/// istilah pendek (cocok sebagai chip yang lebih padat & cepat di-scan).
/// Set [onChanged] untuk mode isi; [readOnly] untuk mode baca (review).
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
    this.icon = Icons.category_outlined,
  });

  final String title;
  final List<String> options;
  final Set<String> selected;
  final ValueChanged<String>? onChanged;
  final TextEditingController? otherController;
  final bool readOnly;
  final bool required;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    if (readOnly) {
      final chosen = options.where(selected.contains).toList();
      final other = otherController?.text ?? '';
      if (chosen.isEmpty && other.isEmpty) return const SizedBox.shrink();

      return Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: HseSectionCard(
          title: title,
          icon: icon,
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final item in chosen) _Chip(label: item, selected: true),
              if (other.isNotEmpty) _Chip(label: other, selected: true),
            ],
          ),
        ),
      );
    }

    final count = options.where(selected.contains).length;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: HseSectionCard(
        title: title,
        icon: icon,
        required: required,
        trailing: HseCountPill(count: count, total: options.length),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final option in options)
                  _Chip(
                    label: option,
                    selected: selected.contains(option),
                    onTap: () => onChanged?.call(option),
                  ),
              ],
            ),
            if (otherController != null) ...[
              const SizedBox(height: 14),
              AppTextField(
                label: 'Other (optional)',
                controller: otherController!,
                hint: 'Fill in manually if not listed above',
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Chip pil: hijau tua solid dengan centang saat dipilih, putih bergaris
/// tepi saat tidak.
class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.selected, this.onTap});

  final String label;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.primary : AppColors.card,
      shape: StadiumBorder(
        side: BorderSide(color: selected ? AppColors.primary : AppColors.border),
      ),
      child: InkWell(
        onTap: onTap,
        customBorder: const StadiumBorder(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (selected) ...[
                const Icon(Icons.check_rounded, size: 15, color: Colors.white),
                const SizedBox(width: 5),
              ],
              Flexible(
                child: Text(
                  label,
                  style: AppTextStyles.caption.copyWith(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: selected ? Colors.white : AppColors.textMid,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
