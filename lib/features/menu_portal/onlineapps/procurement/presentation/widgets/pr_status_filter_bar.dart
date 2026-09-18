import 'package:flutter/material.dart';

import '../../../../../../core/theme/app_colors.dart';
import '../../../../../../core/theme/app_text_styles.dart';
import '../../domain/pr_status.dart';

/// Deret chip filter status, pengganti dropdown "Status" di web.
///
/// [statuses] diambil dari seluruh data (bukan dari hasil pencarian) supaya
/// chip tidak muncul-hilang sewaktu orang mengetik di kolom cari, sementara
/// [counts] mengikuti hasil pencarian supaya angkanya jujur.
class PrStatusFilterBar extends StatelessWidget {
  const PrStatusFilterBar({
    super.key,
    required this.statuses,
    required this.counts,
    required this.totalCount,
    required this.selected,
    required this.onChanged,
  });

  final List<PrStatus> statuses;
  final Map<PrStatus, int> counts;
  final int totalCount;

  /// Null berarti chip "Semua" yang aktif.
  final PrStatus? selected;
  final ValueChanged<PrStatus?> onChanged;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _FilterChip(
            label: 'Semua',
            count: totalCount,
            color: AppColors.primary,
            background: AppColors.primaryLight,
            active: selected == null,
            onTap: () => onChanged(null),
          ),
          for (final status in statuses) ...[
            const SizedBox(width: 8),
            _FilterChip(
              label: status.shortLabel,
              count: counts[status] ?? 0,
              color: status.color,
              background: status.background,
              active: selected == status,
              onTap: () => onChanged(status),
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
            color: active ? color : AppColors.textMid,
          ),
        ),
      ),
    );
  }
}
