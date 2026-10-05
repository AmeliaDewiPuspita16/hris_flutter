import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../domain/payslip.dart';
import 'payslip_amount_format.dart';

/// Kartu hijau di atas detail slip: take home pay, status, dan identitas.
class PayslipHeroCard extends StatelessWidget {
  const PayslipHeroCard({
    super.key,
    required this.payslip,
    required this.hidden,
    this.identity,
  });

  final Payslip payslip;

  /// True menyamarkan nominal.
  final bool hidden;

  /// Mis. "Nama · NIK · Bagian". Null/kosong = tidak ditampilkan.
  final String? identity;

  @override
  Widget build(BuildContext context) {
    final identityText = identity;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        gradient: AppColors.heroGradient,
        borderRadius: BorderRadius.circular(14),
      ),
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
                    const Text(
                      'Take Home Pay',
                      style: TextStyle(fontSize: 11, color: AppColors.bannerAccent),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      payslipAmountText(payslip.netPay, hidden: hidden),
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  payslip.isPaid ? 'Sudah Dibayar' : 'Menunggu',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          if (identityText != null && identityText.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              identityText,
              style: const TextStyle(fontSize: 11, color: AppColors.bannerAccent),
            ),
          ],
        ],
      ),
    );
  }
}
