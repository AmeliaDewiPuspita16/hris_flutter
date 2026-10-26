import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../domain/notification_category.dart';

/// Dropdown jenis tindakan di bawah tab "Action".
///
/// Untuk pengguna dengan banyak peran (mis. admin ITM) daftar Action bisa
/// berisi campuran IT request, EST, procurement, dan indent vehicle. Dropdown
/// ini menyaring per kategori supaya tidak perlu scroll panjang.
///
/// [options] = kategori yang memang ada di daftar Action beserta jumlahnya.
/// [selected] null berarti "All types".
class NotificationActionTypeFilter extends StatelessWidget {
  const NotificationActionTypeFilter({
    super.key,
    required this.options,
    required this.selected,
    required this.onSelected,
  });

  final Map<NotificationCategory, int> options;
  final NotificationCategory? selected;
  final ValueChanged<NotificationCategory?> onSelected;

  @override
  Widget build(BuildContext context) {
    final total = options.values.fold<int>(0, (a, b) => a + b);
    final currentLabel = selected?.label ?? 'All types';
    final currentCount = selected == null ? total : (options[selected] ?? 0);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
      decoration: const BoxDecoration(
        color: AppColors.card,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: PopupMenuButton<NotificationCategory?>(
        tooltip: 'Filter by type',
        position: PopupMenuPosition.under,
        offset: const Offset(0, 6),
        color: AppColors.card,
        onSelected: onSelected,
        itemBuilder: (context) => [
          _item(null, 'All types', total, selected == null),
          for (final entry in options.entries)
            _item(
              entry.key,
              entry.key.label,
              entry.value,
              identical(entry.key, selected),
            ),
        ],
        child: Container(
          height: 38,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Icon(
                selected?.icon ?? Icons.filter_list,
                size: 17,
                color: selected?.color ?? AppColors.textMuted,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  '$currentLabel · $currentCount',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.text,
                  ),
                ),
              ),
              const Icon(
                Icons.keyboard_arrow_down,
                size: 20,
                color: AppColors.textMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }

  PopupMenuItem<NotificationCategory?> _item(
    NotificationCategory? value,
    String label,
    int count,
    bool isSelected,
  ) {
    return PopupMenuItem<NotificationCategory?>(
      value: value,
      child: Row(
        children: [
          Icon(
            value?.icon ?? Icons.filter_list,
            size: 17,
            color: value?.color ?? AppColors.textMuted,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontFamily: AppTextStyles.fontFamily,
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? AppColors.primary : AppColors.text,
              ),
            ),
          ),
          Text(
            '$count',
            style: const TextStyle(
              fontFamily: AppTextStyles.fontFamily,
              fontSize: 11.5,
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}
