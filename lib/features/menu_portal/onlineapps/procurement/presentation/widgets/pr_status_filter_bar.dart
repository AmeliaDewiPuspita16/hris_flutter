import 'package:flutter/material.dart';

import '../../../../../../core/theme/app_colors.dart';
import '../../../../../../core/theme/app_text_styles.dart';
import '../../domain/purchase_requisition_page.dart';

/// Deret chip filter status, pengganti dropdown "Status" di web.
///
/// Angkanya datang dari `summary` server, jadi tetap benar untuk seluruh PR
/// meski baru satu halaman yang termuat. Status bernilai nol tetap
/// ditampilkan supaya deret chip tidak berubah-ubah sewaktu orang mengetik
/// di kolom cari.
class PrStatusFilterBar extends StatelessWidget {
  const PrStatusFilterBar({
    super.key,
    required this.counts,
    required this.selected,
    required this.onChanged,
  });

  final PrStatusCounts counts;

  /// Kode status yang aktif. Null berarti chip "Semua".
  final String? selected;

  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      // Ruang bawah untuk bayangan pill aktif.
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
      child: Row(
        children: [
          _FilterChip(
            label: 'Semua',
            count: counts.all,
            color: AppColors.primary,
            active: selected == null,
            onTap: () => onChanged(null),
          ),
          for (final status in counts.reportedCodes) ...[
            const SizedBox(width: 8),
            _FilterChip(
              label: status.shortLabel,
              count: counts.countFor(status.code),
              color: status.color,
              active: selected == status.code,
              onTap: () => onChanged(status.code),
            ),
          ],
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.count,
    required this.color,
    required this.active,
    required this.onTap,
  });

  final String label;
  final int count;
  final Color color;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    // Status yang kosong ditampilkan pudar: masih bisa ditekan, tapi tidak
    // ikut menarik perhatian di antara yang ada isinya.
    final empty = count == 0 && !active;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      // Gaya pill sama dengan `ItRequestTabBar`, tapi chip aktif memakai
      // warna statusnya sendiri.
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        height: 42,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: active ? AppColors.solid(color) : AppColors.card,
          borderRadius: BorderRadius.circular(22),
          border: active ? null : Border.all(color: AppColors.border),
          boxShadow: active
              ? [
                  BoxShadow(
                    color: AppColors.solid(color).withValues(alpha: 0.25),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Text(
          '$label ($count)',
          style: TextStyle(
            fontFamily: AppTextStyles.fontFamily,
            fontSize: 11.5,
            fontWeight: FontWeight.w600,
            color: active
                ? Colors.white
                : (empty ? AppColors.textMuted : AppColors.text),
          ),
        ),
      ),
    );
  }
}
