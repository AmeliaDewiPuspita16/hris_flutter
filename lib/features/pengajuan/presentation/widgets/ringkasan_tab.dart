import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../domain/leave_balance.dart';
import '../../domain/leave_history_entry.dart';
import '../bloc/balance/leave_balance_bloc.dart';
import '../bloc/balance/leave_balance_state.dart';
import '../bloc/history/leave_history_bloc.dart';
import '../bloc/history/leave_history_state.dart';
import 'leave_detail_sheet.dart';

const _monthNames = [
  'January', 'February', 'March', 'April', 'May', 'June',
  'July', 'August', 'September', 'October', 'November', 'December',
];

/// Tab "Ringkasan" — saldo tiap jenis cuti/izin/lembur, lalu snapshot
/// pengajuan per bulan (default bulan berjalan, bisa digeser ke bulan lain).
///
/// Sengaja dibedakan dari tab Status: tab ini nampilkan riwayat satu bulan
/// tanpa filter jenis/status (buat overview cepat, tap baris = lihat
/// detail), sedangkan tab Status jadi arsip lengkap dengan filter.
/// Sumber datanya [LeaveBalanceBloc] & [LeaveHistoryBloc], keduanya sudah
/// disediakan `PengajuanScreen` di atas tab ini.
class RingkasanTab extends StatefulWidget {
  const RingkasanTab({super.key, this.onSeeAll});

  /// Dipanggil saat "See All" ditekan — `PengajuanScreen` mengisi ini untuk
  /// pindah ke tab Status.
  final VoidCallback? onSeeAll;

  @override
  State<RingkasanTab> createState() => _RingkasanTabState();
}

class _RingkasanTabState extends State<RingkasanTab> {
  late DateTime _selectedMonth = DateTime(DateTime.now().year, DateTime.now().month);

  bool get _isCurrentMonth {
    final now = DateTime.now();
    return _selectedMonth.year == now.year && _selectedMonth.month == now.month;
  }

  void _shiftMonth(int delta) {
    setState(() => _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month + delta));
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _BalanceSummaryCard(),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _MonthArrow(icon: Icons.chevron_left, onTap: () => _shiftMonth(-1)),
                  SizedBox(
                    width: 118,
                    child: Text(
                      '${_monthNames[_selectedMonth.month - 1]} ${_selectedMonth.year}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.text),
                    ),
                  ),
                  _MonthArrow(
                    icon: Icons.chevron_right,
                    onTap: _isCurrentMonth ? null : () => _shiftMonth(1),
                  ),
                ],
              ),
              if (widget.onSeeAll != null)
                InkWell(
                  onTap: widget.onSeeAll,
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'See All',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primary),
                      ),
                      SizedBox(width: 2),
                      Icon(Icons.arrow_forward, size: 14, color: AppColors.primary),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          _RecentSummaryList(month: _selectedMonth),
        ],
      ),
    );
  }
}

class _MonthArrow extends StatelessWidget {
  const _MonthArrow({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Icon(icon, size: 20, color: enabled ? AppColors.text : AppColors.border),
      ),
    );
  }
}

class _BalanceSummaryCard extends StatelessWidget {
  const _BalanceSummaryCard();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LeaveBalanceBloc, LeaveBalanceState>(
      builder: (context, state) {
        if (state.status == LeaveBalanceStatus.loading && state.balances.isEmpty) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (state.status == LeaveBalanceStatus.failure && state.balances.isEmpty) {
          return Center(
            child: Text(
              state.errorMessage ?? 'Failed to load balance.',
              style: const TextStyle(color: AppColors.textMuted),
            ),
          );
        }

        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.bg,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Icon(Icons.spa_outlined, color: AppColors.primary, size: 16),
                  const SizedBox(width: 6),
                  const Text(
                    'Leave Balance',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.text),
                  ),
                  const Spacer(),
                  Text(
                    'As of ${DateFormatter.shortDateID(DateTime.now())}',
                    style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: state.balances.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 6,
                  crossAxisSpacing: 6,
                  childAspectRatio: 2.3,
                ),
                itemBuilder: (context, index) => _BalanceCell(balance: state.balances[index]),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _BalanceCell extends StatelessWidget {
  const _BalanceCell({required this.balance});

  final LeaveBalance balance;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: balance.color.withOpacity(0.35), width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(color: balance.color, shape: BoxShape.circle),
            ),
          ),
          const SizedBox(width: 5),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  balance.label,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.text),
                ),
                const SizedBox(height: 2),
                Text(
                  '${balance.remaining} ${balance.unit}',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.text),
                ),
                Text(
                  balance.total != null ? 'out of ${balance.total}' : 'Accumulated',
                  style: const TextStyle(fontSize: 9, color: AppColors.textMuted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RecentSummaryList extends StatelessWidget {
  const _RecentSummaryList({required this.month});

  final DateTime month;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LeaveHistoryBloc, LeaveHistoryState>(
      builder: (context, state) {
        if (state.status == LeaveHistoryStatus.loading && state.items.isEmpty) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (state.status == LeaveHistoryStatus.failure && state.items.isEmpty) {
          return Center(
            child: Text(
              state.errorMessage ?? 'Failed to load history.',
              style: const TextStyle(color: AppColors.textMuted),
            ),
          );
        }

        final itemsInMonth = state.items
            .where((item) => item.requestDate.year == month.year && item.requestDate.month == month.month)
            .toList();

        if (itemsInMonth.isEmpty) {
          return AppCard(
            padding: const EdgeInsets.symmetric(vertical: 28),
            child: const Column(
              children: [
                Icon(Icons.event_busy_outlined, size: 28, color: AppColors.textMuted),
                SizedBox(height: 8),
                Text(
                  'No leave activity this month',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textMuted),
                ),
              ],
            ),
          );
        }

        return AppCard(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < itemsInMonth.length; i++) ...[
                if (i > 0) const Divider(height: 1, color: AppColors.border),
                _RecentSummaryRow(entry: itemsInMonth[i]),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _RecentSummaryRow extends StatelessWidget {
  const _RecentSummaryRow({required this.entry});

  final LeaveHistoryEntry entry;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => showLeaveDetailSheet(context, entry),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.date,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.text),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    entry.type,
                    style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            StatusBadge(status: entry.status),
          ],
        ),
      ),
    );
  }
}
