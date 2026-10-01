import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// Urutan tabel rekap bulanan.
enum RecapSort { mostLate, mostAbsent, name }

/// Tiga pil pilihan urutan di atas tabel rekap. Yang aktif ditandai garis
/// tepi tipis dan teks tebal — tanpa isian warna.
class RecapSortChips extends StatelessWidget {
  const RecapSortChips({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  final RecapSort selected;
  final ValueChanged<RecapSort> onSelected;

  static const _labels = {
    RecapSort.mostLate: 'Most late',
    RecapSort.mostAbsent: 'Most absent',
    RecapSort.name: 'Name',
  };

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final sort in RecapSort.values)
          _Chip(
            label: _labels[sort]!,
            active: selected == sort,
            onTap: () => onSelected(sort),
          ),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.active,
    required this.onTap,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: active,
      label: 'Sort by $label',
      excludeSemantics: true,
      child: Material(
        color: AppColors.card,
        shape: StadiumBorder(
          side: BorderSide(
            color: active ? AppColors.primary : AppColors.border,
            width: active ? 1.5 : 1,
          ),
        ),
        child: InkWell(
          onTap: onTap,
          customBorder: const StadiumBorder(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                color: active ? AppColors.text : AppColors.textMid,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
