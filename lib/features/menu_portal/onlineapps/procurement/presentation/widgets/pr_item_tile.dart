import 'package:flutter/material.dart';

import '../../../../../../core/theme/app_colors.dart';
import '../../../../../../core/theme/app_text_styles.dart';
import '../../../../../../core/utils/currency_formatter.dart';
import '../../../../../../core/widgets/detail_field_tile.dart';
import '../../domain/pr_line_item.dart';

/// Satu item PR. Tabel enam kolom di web dilipat jadi judul + daftar
/// "label : nilai" karena tabel selebar itu tidak terbaca di layar HP.
class PrItemTile extends StatelessWidget {
  const PrItemTile({
    super.key,
    required this.item,
    required this.number,
    required this.showDivider,
  });

  final PrLineItem item;
  final int number;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        border: showDivider
            ? const Border(bottom: BorderSide(color: AppColors.border))
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$number.',
                style: AppTextStyles.caption.copyWith(color: AppColors.textMid),
              ),
              const SizedBox(width: 6),
              _KindChip(kind: item.kind),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  item.description,
                  style: AppTextStyles.body.copyWith(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    height: 1.35,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          DetailFieldTile(label: 'GL Account', value: item.glAccount ?? '—'),
          DetailFieldTile(label: 'Qty', value: '${item.qty} ${item.unit}'),
          DetailFieldTile(label: 'Est. Price', value: formatRupiah(item.estPrice)),
          DetailFieldTile(
            label: 'Subtotal',
            value: formatRupiah(item.subtotal),
            showDivider: false,
          ),
        ],
      ),
    );
  }
}

class _KindChip extends StatelessWidget {
  const _KindChip({required this.kind});

  final PrItemKind kind;

  @override
  Widget build(BuildContext context) {
    final isGoods = kind == PrItemKind.goods;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: isGoods ? AppColors.tealBg : AppColors.accentBg,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        kind.label,
        style: TextStyle(
          fontFamily: AppTextStyles.fontFamily,
          fontSize: 9,
          fontWeight: FontWeight.w700,
          color: isGoods ? AppColors.teal : AppColors.accent,
        ),
      ),
    );
  }
}
