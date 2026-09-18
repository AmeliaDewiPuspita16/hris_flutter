import 'package:flutter/material.dart';

import '../../../../../../core/theme/app_colors.dart';
import '../../../../../../core/utils/currency_formatter.dart';
import '../../domain/purchase_requisition.dart';
import 'pr_status_badge.dart';

/// Kepala layar detail: total perkiraan dan status PR, dengan gaya yang sama
/// seperti hero di layar detail slip gaji.
class PrDetailHero extends StatelessWidget {
  const PrDetailHero({super.key, required this.requisition});

  final PurchaseRequisition requisition;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        gradient: AppColors.heroGradient,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Est. Total',
                  style: TextStyle(fontSize: 11, color: AppColors.bannerAccent),
                ),
                const SizedBox(height: 2),
                Text(
                  formatRupiah(requisition.estimatedTotal),
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          PrStatusBadge(status: requisition.status, onDark: true),
        ],
      ),
    );
  }
}
