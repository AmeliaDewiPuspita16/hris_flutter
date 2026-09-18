import 'package:flutter/material.dart';

import '../../../../../../core/theme/app_colors.dart';
import '../../../../../../core/theme/app_text_styles.dart';
import '../../../../../../core/utils/currency_formatter.dart';
import '../../../../../../core/utils/date_formatter.dart';
import '../../../../../../core/widgets/app_card.dart';
import '../../domain/purchase_requisition.dart';
import 'pr_item_count_chip.dart';
import 'pr_status_badge.dart';

/// Satu PR di halaman daftar — padanan satu baris tabel di web, dilipat jadi
/// kartu karena 8 kolom tabel tidak muat di layar HP.
class PrCard extends StatelessWidget {
  const PrCard({super.key, required this.requisition, this.onTap});

  final PurchaseRequisition requisition;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  requisition.prNumber,
                  style: AppTextStyles.body.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              PrStatusBadge(status: requisition.status),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${DateFormatter.shortDate(requisition.date)} · ${requisition.section}',
            style: AppTextStyles.caption,
          ),
          const SizedBox(height: 8),
          Text(
            requisition.purpose,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.body.copyWith(fontSize: 13, height: 1.4),
          ),
          const SizedBox(height: 10),
          const Divider(height: 1, thickness: 1, color: AppColors.border),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(
                Icons.person_outline,
                size: 14,
                color: AppColors.textMuted,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  requisition.requestor,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.caption.copyWith(color: AppColors.textMid),
                ),
              ),
              PrItemCountChip(label: requisition.itemCountLabel),
              const SizedBox(width: 8),
              Text(
                formatRupiah(requisition.estimatedTotal),
                style: const TextStyle(
                  fontFamily: AppTextStyles.fontFamily,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
