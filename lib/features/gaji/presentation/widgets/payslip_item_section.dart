import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_card.dart';
import '../../domain/payslip.dart';
import 'payslip_amount_format.dart';

/// Satu bagian di detail slip: judul, daftar komponen, dan totalnya.
/// Dipakai dua kali — Pendapatan dan Potongan.
class PayslipItemSection extends StatelessWidget {
  const PayslipItemSection({
    super.key,
    required this.title,
    required this.items,
    required this.totalLabel,
    required this.total,
    required this.hidden,
    this.isDeduction = false,
  });

  final String title;
  final List<PayslipItem> items;
  final String totalLabel;
  final int total;
  final bool hidden;

  /// Potongan ditulis merah dengan awalan "- ".
  final bool isDeduction;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: AppTextStyles.sectionTitle),
        const SizedBox(height: 8),
        AppCard(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: [
              for (final item in items)
                _ItemRow(item: item, hidden: hidden, isDeduction: isDeduction),
              _TotalRow(label: totalLabel, amount: total, hidden: hidden),
            ],
          ),
        ),
      ],
    );
  }
}

class _ItemRow extends StatelessWidget {
  const _ItemRow({required this.item, required this.hidden, required this.isDeduction});

  final PayslipItem item;
  final bool hidden;
  final bool isDeduction;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 11),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              item.label,
              style: const TextStyle(fontSize: 13, color: AppColors.textMid),
            ),
          ),
          Text(
            '${isDeduction && !hidden ? '- ' : ''}${payslipAmountText(item.amount, hidden: hidden)}',
            style: TextStyle(
              fontSize: 13,
              color: isDeduction ? AppColors.rejected : AppColors.text,
            ),
          ),
        ],
      ),
    );
  }
}

class _TotalRow extends StatelessWidget {
  const _TotalRow({required this.label, required this.amount, required this.hidden});

  final String label;
  final int amount;
  final bool hidden;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.text,
            ),
          ),
          Text(
            payslipAmountText(amount, hidden: hidden),
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.text,
            ),
          ),
        ],
      ),
    );
  }
}
