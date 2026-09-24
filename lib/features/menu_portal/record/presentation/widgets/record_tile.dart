import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../../../core/widgets/app_card.dart';
import '../../domain/record_item.dart';

/// Satu baris di halaman Records: ikon, judul + badge owner (bisa lebih
/// dari satu), dan chevron di kanan.
class RecordTile extends StatelessWidget {
  const RecordTile({super.key, required this.item});

  final RecordItem item;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: item.onTap,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: item.background,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(item.icon, size: 21, color: item.color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.label,
                  style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    for (final owner in item.owners) _OwnerBadge(name: owner),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.chevron_right, size: 20, color: AppColors.textMuted),
        ],
      ),
    );
  }
}

/// Badge nama owner/PIC — abu-abu netral, mengikuti pola badge "LIBUR" di
/// attendance_row (neutral/neutralBg), dan dibuat kecil supaya tidak
/// mendominasi baris.
class _OwnerBadge extends StatelessWidget {
  const _OwnerBadge({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.neutralBg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        name,
        style: TextStyle(
          fontFamily: AppTextStyles.fontFamily,
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: AppColors.neutral,
        ),
      ),
    );
  }
}
