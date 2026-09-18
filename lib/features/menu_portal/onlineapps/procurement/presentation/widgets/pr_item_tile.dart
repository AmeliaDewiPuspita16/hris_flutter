import 'package:flutter/material.dart';

import '../../../../../../core/theme/app_colors.dart';
import '../../../../../../core/theme/app_text_styles.dart';
import '../../../../../../core/utils/currency_formatter.dart';
import '../../domain/pr_line_item.dart';

/// Satu item PR.
///
/// Tabel enam kolom di web dipadatkan jadi tiga baris: nama barang, lalu
/// perhitungan "qty x harga satuan" dan nomor GL di kiri dengan subtotal
/// sebagai angka paling menonjol di kanan. Bentuk "label : nilai" per kolom
/// dilepas karena keempat labelnya terulang di tiap item dan membuat
/// subtotal — angka yang paling dicari — tenggelam di antara nilai lain.
class PrItemTile extends StatelessWidget {
  const PrItemTile({super.key, required this.item, required this.showDivider});

  final PrLineItem item;
  final bool showDivider;

  /// Lebar kolom nomor, dipakai lagi untuk menjorokkan baris di bawahnya
  /// supaya sejajar dengan nama barang.
  static const _numberColumnWidth = 20.0;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
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
              SizedBox(
                width: _numberColumnWidth,
                child: Text(
                  '${item.lineNumber}',
                  style: AppTextStyles.caption.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textMuted,
                  ),
                ),
              ),
              _KindChip(kind: item.kind),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.description,
                      style: AppTextStyles.body.copyWith(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        height: 1.35,
                      ),
                    ),
                    if (item.specification != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        item.specification!,
                        style: AppTextStyles.caption.copyWith(height: 1.4),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.only(left: _numberColumnWidth),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${item.quantityLabel} × ${formatRupiah(item.unitPrice)}',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.textMid,
                        ),
                      ),
                      // GL Account baru terisi setelah Finance memprosesnya.
                      // Selama kosong barisnya dilewati saja — di layout
                      // seringkas ini satu baris "—" tidak membawa informasi.
                      if (item.glAccount != null) ...[
                        const SizedBox(height: 3),
                        Text(
                          'GL ${item.glAccount}'
                          '${item.segment != null ? ' · ${item.segment}' : ''}',
                          style: AppTextStyles.caption,
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                // Gelap, bukan hijau: hijau disimpan untuk Estimated Total di
                // kaki daftar supaya angka pamungkasnya tetap menonjol.
                Text(
                  formatRupiah(item.totalPrice),
                  style: const TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AppColors.text,
                  ),
                ),
              ],
            ),
          ),
          if (item.notes != null)
            Padding(
              padding: const EdgeInsets.only(left: _numberColumnWidth, top: 6),
              child: Text(
                item.notes!,
                style: AppTextStyles.caption.copyWith(
                  fontStyle: FontStyle.italic,
                  height: 1.4,
                ),
              ),
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
