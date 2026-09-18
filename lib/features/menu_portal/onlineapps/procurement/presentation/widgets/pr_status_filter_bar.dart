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
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _FilterChip(
            label: 'Semua',
            count: counts.all,
            color: AppColors.primary,
            background: AppColors.primaryLight,
            active: selected == null,
            onTap: () => onChanged(null),
          ),
          for (final status in counts.reportedCodes) ...[
            const SizedBox(width: 8),
            _FilterChip(
              label: status.shortLabel,
              count: counts.countFor(status.code),
              color: status.color,
              background: status.background,
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
    required this.background,
    required this.active,
    required this.onTap,
  });

  final String label;
  final int count;
  final Color color;
  final Color background;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    // Status yang kosong ditampilkan pudar: masih bisa ditekan, tapi tidak
    // ikut menarik perhatian di antara yang ada isinya.
    final empty = count == 0 && !active;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: active ? background : AppColors.card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: active ? color : AppColors.border,
            width: active ? 1.4 : 1,
          ),
        ),
        child: Text(
          '$label ($count)',
          style: TextStyle(
            fontFamily: AppTextStyles.fontFamily,
            fontSize: 11,
            fontWeight: active ? FontWeight.w700 : FontWeight.w600,
            color: active
                ? color
                : (empty ? AppColors.textMuted : AppColors.textMid),
          ),
        ),
      ),
    );
  }
}
