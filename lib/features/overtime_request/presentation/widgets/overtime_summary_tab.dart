import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_card.dart';
import '../../domain/overtime_day.dart';
import '../../domain/overtime_format.dart';
import '../../domain/overtime_month.dart';
import '../bloc/summary/overtime_summary_bloc.dart';
import '../bloc/summary/overtime_summary_event.dart';
import '../bloc/summary/overtime_summary_state.dart';

/// Tab "Summary" — lembur yang sudah terjadi pada bulan terpilih (realisasi
/// dari absensi, `GET .../hris/overtime`): total jam, jumlah hari, dan
/// daftar per hari. Datanya dimuat [OvertimeSummaryBloc].
class OvertimeSummaryTab extends StatelessWidget {
  const OvertimeSummaryTab({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<OvertimeSummaryBloc, OvertimeSummaryState>(
      builder: (context, state) {
        final bloc = context.read<OvertimeSummaryBloc>();
        final now = DateTime.now();
        final isCurrentMonth =
            state.month.year == now.year && state.month.month == now.month;

        void goTo(int delta) => bloc.add(OvertimeSummaryMonthChanged(
              DateTime(state.month.year, state.month.month + delta),
            ));

        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _MonthNav(
                month: state.month,
                onPrevious: () => goTo(-1),
                onNext: isCurrentMonth ? null : () => goTo(1),
              ),
              const SizedBox(height: 12),
              _buildBody(context, state),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBody(BuildContext context, OvertimeSummaryState state) {
    switch (state.status) {
      case OvertimeSummaryStatus.initial:
      case OvertimeSummaryStatus.loading:
        return const Padding(
          padding: EdgeInsets.symmetric(vertical: 48),
          child: Center(child: CircularProgressIndicator()),
        );

      case OvertimeSummaryStatus.failure:
        return _ErrorState(
          message: state.errorMessage ?? 'Failed to load overtime.',
          onRetry: () => context
              .read<OvertimeSummaryBloc>()
              .add(const OvertimeSummaryRetried()),
        );

      case OvertimeSummaryStatus.success:
        final data = state.data;
        if (data == null) return const _EmptyMonth();

        return _Content(data: data);
    }
  }
}

class _Content extends StatelessWidget {
  const _Content({required this.data});

  final OvertimeMonth data;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _TotalsCard(
          totalMinutes: data.totalMinutes,
          dayCount: data.daysWithOvertime,
        ),
        const SizedBox(height: 16),
        if (data.days.isEmpty)
          const _EmptyMonth()
        else
          AppCard(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var i = 0; i < data.days.length; i++) ...[
                  if (i > 0) const Divider(height: 1, color: AppColors.border),
                  _DayRow(day: data.days[i]),
                ],
              ],
            ),
          ),
        const SizedBox(height: 12),
        const Text(
          'Overtime is calculated from your attendance log, based on the '
          'time you check out after your shift ends.',
          style: TextStyle(fontSize: 11, color: AppColors.textMuted, height: 1.4),
        ),
      ],
    );
  }
}

class _MonthNav extends StatelessWidget {
  const _MonthNav({
    required this.month,
    required this.onPrevious,
    required this.onNext,
  });

  final DateTime month;
  final VoidCallback onPrevious;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _MonthArrow(icon: Icons.chevron_left, onTap: onPrevious),
        SizedBox(
          width: 130,
          child: Text(
            DateFormat('MMMM yyyy', 'en_US').format(month),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.text,
            ),
          ),
        ),
        _MonthArrow(icon: Icons.chevron_right, onTap: onNext),
      ],
    );
  }
}

class _TotalsCard extends StatelessWidget {
  const _TotalsCard({required this.totalMinutes, required this.dayCount});

  final int totalMinutes;
  final int dayCount;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
      child: Row(
        children: [
          Expanded(
            child: _StatCell(
              label: 'TOTAL OVERTIME',
              value: formatOvertimeHours(totalMinutes),
              unit: 'hrs',
            ),
          ),
          Container(width: 1, height: 44, color: AppColors.border),
          Expanded(
            child: _StatCell(
              label: 'DAYS WITH OVERTIME',
              value: '$dayCount',
              unit: dayCount == 1 ? 'day' : 'days',
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCell extends StatelessWidget {
  const _StatCell({required this.label, required this.value, required this.unit});

  final String label;
  final String value;
  final String unit;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.3,
            color: AppColors.textMuted,
          ),
        ),
        const SizedBox(height: 6),
        Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: value,
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: AppColors.overtime,
                ),
              ),
              TextSpan(
                text: ' $unit',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MonthArrow extends StatelessWidget {
  const _MonthArrow({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Icon(
          icon,
          size: 20,
          color: onTap != null ? AppColors.text : AppColors.border,
        ),
      ),
    );
  }
}

class _DayRow extends StatelessWidget {
  const _DayRow({required this.day});

  final OvertimeDay day;

  String get _detail {
    final checkIn = day.checkIn;
    final checkOut = day.checkOut;

    final times = checkIn != null && checkOut != null
        ? '${formatClock(checkIn)} – ${formatClock(checkOut)}'
        : '-';

    return day.shift == null ? times : '$times · Shift ${day.shift}';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  DateFormat('EEE, d MMM', 'en_US').format(day.date),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.text,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _detail,
                  style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.overtimeBg,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              formatOvertimeDuration(day.minutes),
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.overtime,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyMonth extends StatelessWidget {
  const _EmptyMonth();

  @override
  Widget build(BuildContext context) {
    return const AppCard(
      padding: EdgeInsets.symmetric(vertical: 28),
      child: Column(
        children: [
          Icon(Icons.more_time_outlined, size: 28, color: AppColors.textMuted),
          SizedBox(height: 8),
          Text(
            'No overtime this month',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Column(
        children: [
          const Icon(Icons.cloud_off_outlined, size: 32, color: AppColors.textMuted),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: onRetry,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: const BorderSide(color: AppColors.primary),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Try again'),
          ),
        ],
      ),
    );
  }
}
