import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../domain/notification_filter.dart';

/// Penyaring notifikasi berbentuk tab bergaris bawah.
///
/// Tab dibagi rata selebar layar ([Expanded]) dengan teks di tengah. Dulu
/// lebarnya mengikuti teks, tapi setelah tab Payroll & Announcements
/// dinonaktifkan tersisa dua tab yang menumpuk di tepi kiri.
class NotificationFilterTabs extends StatelessWidget {
  const NotificationFilterTabs({
    super.key,
    required this.selected,
    required this.counts,
    required this.onSelected,
  });

  final NotificationFilter selected;

  /// Jumlah yang belum dibaca per filter. Yang nol tetap tampil, tapi tanpa
  /// angka — supaya mata langsung tertuju ke yang masih menumpuk.
  final Map<NotificationFilter, int> counts;

  final ValueChanged<NotificationFilter> onSelected;

  @override
  Widget build(BuildContext context) {
    final filters = NotificationFilter.values;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.card,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          for (final filter in filters)
            Expanded(
              child: _FilterTab(
                filter: filter,
                count: counts[filter] ?? 0,
                isActive: filter == selected,
                onTap: () => onSelected(filter),
              ),
            ),
        ],
      ),
    );
  }
}

class _FilterTab extends StatelessWidget {
  const _FilterTab({
    required this.filter,
    required this.count,
    required this.isActive,
    required this.onTap,
  });

  final NotificationFilter filter;
  final int count;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = isActive ? AppColors.primary : AppColors.textMuted;

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 13),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isActive ? AppColors.primary : Colors.transparent,
              width: 2.5,
            ),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              filter.label,
              style: TextStyle(
                fontFamily: AppTextStyles.fontFamily,
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
            if (count > 0) ...[
              const SizedBox(width: 4),
              Text(
                '$count',
                style: TextStyle(
                  fontFamily: AppTextStyles.fontFamily,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
