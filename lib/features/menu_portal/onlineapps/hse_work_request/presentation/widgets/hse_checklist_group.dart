import 'package:flutter/material.dart';

import '../../../../../../../core/theme/app_colors.dart';
import '../../../../../../../core/theme/app_text_styles.dart';
import '../../../../../../../core/widgets/app_text_field.dart';
import 'hse_page_chrome.dart';

/// Satu grup checklist bertitel, mis. "General Checklist", dalam kartu
/// [HseSectionCard].
///
/// Set [onChanged] & [otherController] untuk mode isi (form Add Request);
/// [readOnly] untuk mode baca (review) — item yang tidak tercentang tidak
/// ditampilkan sama sekali di mode baca.
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
    this.icon = Icons.fact_check_outlined,
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
      final hasOther = otherController?.text.isNotEmpty ?? false;

      if (chosen.isEmpty && !hasOther) {
        return const SizedBox.shrink();
      }

      return Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: HseSectionCard(
          title: title,
          icon: icon,
          child: Column(
            children: [
              for (final item in chosen) _ReadOnlyRow(label: item),
              if (hasOther) _ReadOnlyRow(label: otherController!.text),
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
            for (final option in options) ...[
              _CheckRow(
                label: option,
                checked: selected.contains(option),
                onTap: () => onChanged?.call(option),
              ),
              const SizedBox(height: 8),
            ],
            if (otherController != null) ...[
              const SizedBox(height: 4),
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

/// Pil kecil "3/8" — berapa pilihan yang sudah dicentang.
class HseCountPill extends StatelessWidget {
  const HseCountPill({super.key, required this.count, required this.total});

  final int count;
  final int total;

  @override
  Widget build(BuildContext context) {
    final any = count > 0;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: any ? AppColors.primary : AppColors.neutralBg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '$count/$total',
        style: AppTextStyles.caption.copyWith(
          fontSize: 11.5,
          fontWeight: FontWeight.w800,
          color: any ? Colors.white : AppColors.textMuted,
        ),
      ),
    );
  }
}

/// Satu baris checklist: kotak bersudut yang ikut berwarna saat dicentang.
class _CheckRow extends StatelessWidget {
  const _CheckRow({required this.label, required this.checked, required this.onTap});

  final String label;
  final bool checked;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: checked ? AppColors.presentBg : AppColors.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: checked ? AppColors.primaryText.withValues(alpha: 0.35) : AppColors.border,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: checked ? AppColors.primary : AppColors.card,
                  borderRadius: BorderRadius.circular(7),
                  border: Border.all(
                    color: checked ? AppColors.primary : AppColors.textMuted,
                    width: 1.6,
                  ),
                ),
                child: checked
                    ? const Icon(Icons.check_rounded, size: 16, color: Colors.white)
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: AppTextStyles.body.copyWith(
                    fontSize: 13.5,
                    height: 1.4,
                    color: checked ? AppColors.text : AppColors.textMid,
                    fontWeight: checked ? FontWeight.w600 : FontWeight.w400,
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

class _ReadOnlyRow extends StatelessWidget {
  const _ReadOnlyRow({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.check_circle_rounded, size: 18, color: AppColors.present),
          const SizedBox(width: 10),
          Expanded(
            child: Text(label, style: AppTextStyles.body.copyWith(fontSize: 13.5, height: 1.4)),
          ),
        ],
      ),
    );
  }
}
