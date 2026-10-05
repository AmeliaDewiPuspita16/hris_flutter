import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// Baris chip tahun. Hanya menggambar; pilihan diteruskan lewat [onSelected].
class PayslipYearSelector extends StatelessWidget {
  const PayslipYearSelector({
    super.key,
    required this.years,
    required this.selected,
    required this.onSelected,
  });

  final List<int> years;
  final int selected;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
      child: Row(
        children: [
          for (final year in years) ...[
            _YearChip(
              year: year,
              isSelected: year == selected,
              onTap: () => onSelected(year),
            ),
            const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }
}

class _YearChip extends StatelessWidget {
  const _YearChip({required this.year, required this.isSelected, required this.onTap});

  final int year;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: isSelected,
      label: 'Tahun $year',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 18),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : Colors.transparent,
            border: Border.all(color: AppColors.primary, width: 1.5),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            '$year',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isSelected ? Colors.white : AppColors.primary,
            ),
          ),
        ),
      ),
    );
  }
}
