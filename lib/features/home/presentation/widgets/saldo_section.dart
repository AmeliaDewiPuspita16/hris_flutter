import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_shimmer.dart';
import '../../domain/quota_balance.dart';
import 'section_header.dart';

/// Bagian kartu ringkasan Beranda ("This month").
///
/// Kartu yang punya pembanding disusun dua kolom, lalu kartu tanpa
/// pembanding menyusul selebar layar. Pemisahan ini bikin barisnya tetap
/// rapi berapa pun jumlah kartu yang muncul.
class SaldoSection extends StatelessWidget {
  const SaldoSection({
    super.key,
    required this.title,
    required this.balances,
    required this.actionLabel,
    required this.onSeeAll,
    this.isLoading = false,
    this.errorMessage,
    this.onRetry,
  });

  static const _gap = 12.0;

  final String title;
  final List<QuotaBalance> balances;
  final String actionLabel;
  final VoidCallback onSeeAll;

  /// True selama data pertama dimuat dan belum ada kartu untuk ditampilkan.
  final bool isLoading;

  /// Ditampilkan bila tidak ada kartu sama sekali karena pemuatan gagal.
  final String? errorMessage;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SectionHeader(
            title: title,
            actionLabel: actionLabel,
            actionIcon: Icons.arrow_forward,
            onActionTap: onSeeAll,
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: _buildBody(),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (balances.isEmpty && isLoading) return const _Skeleton();
    if (balances.isEmpty && errorMessage != null) {
      return Padding(
        padding: const EdgeInsets.only(bottom: _gap),
        child: _ErrorCard(message: errorMessage!, onRetry: onRetry),
      );
    }

    final gridCards = balances.where((b) => !b.isWide).toList();
    final wideCards = balances.where((b) => b.isWide).toList();

    return Column(
      children: [
        for (var i = 0; i < gridCards.length; i += 2)
          Padding(
            padding: const EdgeInsets.only(bottom: _gap),
            child: _CardRow(
              left: gridCards[i],
              right: i + 1 < gridCards.length ? gridCards[i + 1] : null,
            ),
          ),
        for (final balance in wideCards)
          Padding(
            padding: const EdgeInsets.only(bottom: _gap),
            child: _BalanceCard(balance: balance),
          ),
      ],
    );
  }
}

class _Skeleton extends StatelessWidget {
  const _Skeleton();

  @override
  Widget build(BuildContext context) {
    return const AppShimmer(
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: ShimmerBox(height: 104, borderRadius: 12)),
              SizedBox(width: SaldoSection._gap),
              Expanded(child: ShimmerBox(height: 104, borderRadius: 12)),
            ],
          ),
          SizedBox(height: SaldoSection._gap),
          ShimmerBox(height: 80, borderRadius: 12),
          SizedBox(height: SaldoSection._gap),
        ],
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.message, this.onRetry});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontFamily: AppTextStyles.fontFamily,
                fontSize: 13,
                color: AppColors.textMuted,
              ),
            ),
          ),
          if (onRetry != null)
            TextButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}

/// Sepasang kartu berdampingan. Keduanya dibuat setinggi yang tertinggi
/// supaya tidak ada kartu yang menggantung lebih pendek.
class _CardRow extends StatelessWidget {
  const _CardRow({required this.left, this.right});

  final QuotaBalance left;
  final QuotaBalance? right;

  @override
  Widget build(BuildContext context) {
    final second = right;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: _BalanceCard(balance: left)),
          const SizedBox(width: SaldoSection._gap),
          Expanded(
            child: second == null
                ? const SizedBox.shrink()
                : _BalanceCard(balance: second),
          ),
        ],
      ),
    );
  }
}

class _BalanceCard extends StatelessWidget {
  const _BalanceCard({required this.balance});

  final QuotaBalance balance;

  @override
  Widget build(BuildContext context) {
    final progress = balance.progress;

    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            balance.label.toUpperCase(),
            style: TextStyle(
              fontFamily: AppTextStyles.fontFamily,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                balance.formattedValue,
                style: TextStyle(
                  fontFamily: AppTextStyles.fontFamily,
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: AppColors.text,
                  height: 1,
                ),
              ),
              const SizedBox(width: 6),
              // Expanded mendorong catatan ke sisi kanan pada kartu lebar.
              Expanded(
                child: Text(
                  balance.caption,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    fontSize: 12,
                    color: AppColors.textMuted,
                  ),
                ),
              ),
              if (balance.note != null)
                Text(
                  balance.note!,
                  style: TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    fontSize: 11,
                    color: AppColors.textMuted,
                  ),
                ),
            ],
          ),
          if (progress != null) ...[
            const SizedBox(height: 14),
            ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 6,
                backgroundColor: AppColors.border,
                valueColor: AlwaysStoppedAnimation<Color>(
                  AppColors.primaryText,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
