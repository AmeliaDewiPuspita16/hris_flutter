import 'package:flutter/material.dart';

import '../../../../../../core/theme/app_colors.dart';
import '../../../../../../core/theme/app_text_styles.dart';
import '../../domain/need_option.dart';

/// Daftar "What do you need?": baris-baris yang menempel jadi satu grup
/// tanpa jarak sama sekali — opsi yang belum dipilih tetap ringkas, opsi yang dipilih (beserta field
/// tambahannya, kalau ada) jelas menonjol.
class NeedOptionGroup extends StatelessWidget {
  const NeedOptionGroup({
    super.key,
    required this.options,
    required this.selectedId,
    required this.onSelect,
    required this.expandedChildBuilder,
  });

  final List<NeedOption> options;
  final String? selectedId;
  final ValueChanged<String> onSelect;

  /// Dipanggil untuk opsi yang sedang terpilih untuk merender field
  /// tambahannya (chip pilihan, text field, atau sub-form) — null berarti
  /// opsi itu tidak punya field tambahan.
  final Widget? Function(NeedOption option) expandedChildBuilder;

  @override
  Widget build(BuildContext context) {
    final selectedIndex = options.indexWhere((o) => o.id == selectedId);

    if (selectedIndex == -1) {
      // Belum ada yang dipilih — semua baris nempel jadi satu grup.
      return _OptionGroupCard(options: options, selectedId: null, onSelect: onSelect);
    }

    final before = options.sublist(0, selectedIndex);
    final selected = options[selectedIndex];
    final after = options.sublist(selectedIndex + 1);
    final expandedChild = expandedChildBuilder(selected);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (before.isNotEmpty) ...[
          _OptionGroupCard(options: before, selectedId: null, onSelect: onSelect),
          const SizedBox(height: 8),
        ],
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.primary, width: 1.5),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _OptionRow(option: selected, selected: true, onTap: () => onSelect(selected.id)),
              if (expandedChild != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(40, 0, 14, 14),
                  child: expandedChild,
                ),
            ],
          ),
        ),
        if (after.isNotEmpty) ...[
          const SizedBox(height: 8),
          _OptionGroupCard(options: after, selectedId: null, onSelect: onSelect),
        ],
      ],
    );
  }
}

/// Satu grup baris yang menempel (tidak ada opsi terpilih di dalamnya).
class _OptionGroupCard extends StatelessWidget {
  const _OptionGroupCard({
    required this.options,
    required this.selectedId,
    required this.onSelect,
  });

  final List<NeedOption> options;
  final String? selectedId;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < options.length; i++) ...[
            if (i > 0)
              Divider(height: 1, color: AppColors.border.withValues(alpha: 0.7)),
            _OptionRow(
              option: options[i],
              selected: options[i].id == selectedId,
              onTap: () => onSelect(options[i].id),
            ),
          ],
        ],
      ),
    );
  }
}

class _OptionRow extends StatelessWidget {
  const _OptionRow({
    required this.option,
    required this.selected,
    required this.onTap,
  });

  final NeedOption option;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              selected ? Icons.radio_button_checked : Icons.radio_button_off,
              size: 18,
              color: selected ? AppColors.primary : AppColors.textMuted,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                option.label,
                style: AppTextStyles.body.copyWith(
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}