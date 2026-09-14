import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../domain/quota_balance.dart';
import 'section_header.dart';

/// Deretan kartu saldo yang bisa digeser ke samping.
class SaldoSection extends StatelessWidget {
  const SaldoSection({
    super.key,
    required this.balances,
    required this.onSeeAll,
  });

  final List<QuotaBalance> balances;
  final VoidCallback onSeeAll;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SectionHeader(
            title: 'Saldo Saya',
            actionLabel: 'Lihat Semua',
            onActionTap: onSeeAll,
          ),
          const SizedBox(height: 10),
          // Tingginya mengikuti kartu tertinggi lewat IntrinsicHeight, bukan
          // angka tetap. Label seperti "CEK KESEHATAN" yang jatuh ke dua baris
          // dulu bikin kartunya overflow karena tingginya dipatok 92px.
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (var i = 0; i < balances.length; i++) ...[
                    if (i > 0) const SizedBox(width: 10),
                    _QuotaCard(balance: balances[i]),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuotaCard extends StatelessWidget {
  const _QuotaCard({required this.balance});

  final QuotaBalance balance;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 120,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: balance.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: balance.color.withValues(alpha: 0.19)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            balance.label.toUpperCase(),
            style: TextStyle(
              fontFamily: AppTextStyles.fontFamily,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: balance.color,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${balance.value}',
            style: TextStyle(
              fontFamily: AppTextStyles.fontFamily,
              fontSize: 26,
              fontWeight: FontWeight.w900,
              color: balance.color,
              height: 1,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            balance.caption,
            style: const TextStyle(
              fontFamily: AppTextStyles.fontFamily,
              fontSize: 10,
              color: AppColors.textMuted,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
