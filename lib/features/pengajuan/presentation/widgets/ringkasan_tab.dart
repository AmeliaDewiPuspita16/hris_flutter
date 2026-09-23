import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_card.dart';
import '../../domain/leave_balance.dart';
import '../bloc/balance/leave_balance_bloc.dart';
import '../bloc/balance/leave_balance_state.dart';

/// Tab "Ringkasan" — kartu saldo tiap jenis cuti/izin/lembur. Sumbernya
/// [LeaveBalanceBloc] yang disediakan `PengajuanScreen`.
class RingkasanTab extends StatelessWidget {
  const RingkasanTab({super.key});

  @override
  Widget build(BuildContext context) {
    final year = DateTime.now().year;

    return BlocBuilder<LeaveBalanceBloc, LeaveBalanceState>(
      builder: (context, state) {
        if (state.status == LeaveBalanceStatus.loading && state.balances.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state.status == LeaveBalanceStatus.failure && state.balances.isEmpty) {
          return Center(
            child: Text(
              state.errorMessage ?? 'Gagal memuat saldo.',
              style: const TextStyle(color: AppColors.textMuted),
            ),
          );
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Saldo cuti & izin tahun $year',
                style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
              ),
              const SizedBox(height: 14),
              ...state.balances.map(
                (balance) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _BalanceCard(balance: balance),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _BalanceCard extends StatelessWidget {
  const _BalanceCard({required this.balance});

  final LeaveBalance balance;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: balance.background,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        balance.label,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: balance.color,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      balance.total != null
                          ? 'Terpakai ${balance.used} dari ${balance.total} ${balance.unit}'
                          : 'Terkumulasi: ${balance.used} ${balance.unit}',
                      style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${balance.remaining}',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: balance.color,
                      height: 1,
                    ),
                  ),
                  Text(
                    balance.total != null ? 'Tersisa' : 'Saldo',
                    style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
                  ),
                ],
              ),
            ],
          ),
          if (balance.usageRatio != null) ...[
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: balance.usageRatio,
                minHeight: 6,
                backgroundColor: AppColors.border,
                valueColor: AlwaysStoppedAnimation(balance.color),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
