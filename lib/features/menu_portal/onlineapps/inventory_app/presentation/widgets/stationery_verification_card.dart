import 'package:flutter/material.dart';

import '../../../../../../core/theme/app_colors.dart';
import '../../../../../../core/theme/app_text_styles.dart';
import '../../domain/stationery_item_option.dart';
import '../../domain/stationery_request_item.dart';
import 'stationery_action_button.dart';
import 'stationery_request_parts.dart';

/// Kartu satu request yang menunggu verifikasi (baris tabel "Verification
/// Requests" di web). Susunannya sama dengan [StationeryRequestRow]: ikon
/// barang, nama, "kode · peminta", alasan, lalu kolom kanan.
///
/// Kolom kanan memuat jumlah yang diminta DAN stok barang tepat di bawahnya,
/// jadi verifier bisa membandingkan keduanya sekilas (merah + ikon peringatan
/// bila permintaan melebihi stok). Footer berisi Reject dan Approve dengan
/// lebar sama.
class StationeryVerificationCard extends StatelessWidget {
  const StationeryVerificationCard({
    super.key,
    required this.item,
    required this.onApprove,
    required this.onReject,
    this.onTap,
  });

  final StationeryRequestItem item;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  /// Ketuk kartu: buka halaman detail.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return StationeryCard(
      onTap: onTap,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.itemName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.body.copyWith(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 2),
                    StationeryMetaLine(
                      code: item.code,
                      requester: item.requesterName,
                      isMine: item.isMine,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      item.reasonLabel,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.caption.copyWith(
                        height: 1.4,
                        color: item.hasReason ? null : AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  StationeryQuantityText(label: item.quantityLabel),
                  if (item.stock != null) ...[
                    const SizedBox(height: 2),
                    _StockLabel(item: item),
                  ],
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: StationeryActionButton(
                  label: 'Reject',
                  icon: Icons.close_rounded,
                  filled: false,
                  height: 36,
                  onPressed: onReject,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: StationeryActionButton(
                  label: 'Approve',
                  icon: Icons.check_rounded,
                  filled: true,
                  height: 36,
                  onPressed: onApprove,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// "Stock 14 PACK" di bawah chip jumlah. Merah dengan ikon peringatan bila
/// jumlah yang diminta melebihi stok.
class _StockLabel extends StatelessWidget {
  const _StockLabel({required this.item});

  final StationeryRequestItem item;

  @override
  Widget build(BuildContext context) {
    final stock = item.stock!;
    final short = item.quantity > stock;
    final color = short ? AppColors.rejected : AppColors.textMuted;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (short) ...[
          Icon(Icons.warning_amber_rounded, size: 13, color: color),
          const SizedBox(width: 3),
        ],
        Text(
          'Stock ${formatInventoryQuantity(stock)}${item.unit.isEmpty ? '' : ' ${item.unit}'}',
          style: AppTextStyles.caption.copyWith(
            color: color,
            fontWeight: short ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
