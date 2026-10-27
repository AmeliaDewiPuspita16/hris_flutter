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
    this.counts = const [],
    required this.selectedIndex,
    required this.onChanged,
  });

  final List<String> labels;

  /// Jumlah dokumen per tab, sejajar dengan [labels]; null/kosong = tanpa
  /// angka.
  final List<int?> counts;
  final int selectedIndex;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      // Ruang bawah untuk bayangan pill aktif.
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
      child: Row(
        children: [
          for (var i = 0; i < labels.length; i++) ...[
            if (i > 0) const SizedBox(width: 8),
            _TabChip(
              label: labels[i],
              count: i < counts.length ? counts[i] : null,
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
  const _TabChip({required this.label, this.count, required this.active, required this.onTap});

  final String label;
  final int? count;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        height: 42,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        alignment: Alignment.center,
        // Gaya pill sama dengan `ItRequestTabBar`.
        decoration: BoxDecoration(
          color: active ? AppColors.primary : AppColors.card,
          borderRadius: BorderRadius.circular(22),
          border: active ? null : Border.all(color: AppColors.border),
          boxShadow: active
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.25),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontFamily: AppTextStyles.fontFamily,
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: active ? Colors.white : AppColors.text,
              ),
            ),
            if (count case final count?) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
                decoration: BoxDecoration(
                  color: active ? Colors.white.withValues(alpha: 0.2) : AppColors.neutralBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: active ? Colors.white : AppColors.textMid,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
