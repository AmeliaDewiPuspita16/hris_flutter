import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../domain/payslip.dart';

/// Satu baris slip gaji di daftar: periode, take home pay, dan status.
class PayslipCard extends StatelessWidget {
  const PayslipCard({super.key, required this.payslip, required this.onTap});

  final Payslip payslip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(payslip.periodLabel, style: AppTextStyles.sectionTitle),
                const SizedBox(height: 4),
                const Text('Take home pay', style: AppTextStyles.caption),
                const SizedBox(height: 2),
                Text(
                  formatRupiah(payslip.netPay),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              StatusBadge(
                status: payslip.isPaid ? AppStatus.present : AppStatus.pending,
                label: payslip.isPaid ? 'Sudah Dibayar' : 'Menunggu',
              ),
              const SizedBox(height: 8),
              const Icon(Icons.chevron_right, size: 18, color: AppColors.textMuted),
            ],
          ),
        ],
      ),
    );
  }
}
