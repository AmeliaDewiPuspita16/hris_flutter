import 'package:flutter/material.dart';

import '../../../../../../../core/theme/app_colors.dart';
import '../../../../../../../core/theme/app_text_styles.dart';

/// Deret chip tab kategori dokumen (Manual, SOP, dst), dipakai bersama oleh
/// halaman Master Document File dan Master Edited File.
///
/// Pola sama dengan `PrStatusFilterBar` di Procurement: duduk langsung di
/// atas `AppColors.bg`, tanpa dibungkus container putih + garis bawah.
class DocumentTabBar extends StatelessWidget {
  const DocumentTabBar({
    super.key,
    required this.labels,
    required this.selectedIndex,
    required this.onChanged,
  });

  final List<String> labels;
  final int selectedIndex;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          for (var i = 0; i < labels.length; i++) ...[
            if (i > 0) const SizedBox(width: 8),
            _TabChip(
              label: labels[i],
              active: selectedIndex == i,
              onTap: () => onChanged(i),
            ),
          ],
        ],
      ),
    );
  }
}

class _TabChip extends StatelessWidget {
  const _TabChip({required this.label, required this.active, required this.onTap});

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: active ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: active ? AppColors.primary : AppColors.border, width: 1.5),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: AppTextStyles.fontFamily,
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: active ? Colors.white : AppColors.textMuted,
          ),
        ),
      ),
    );
  }
}
