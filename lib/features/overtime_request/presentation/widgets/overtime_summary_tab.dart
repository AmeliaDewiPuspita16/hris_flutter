import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_card.dart';
import '../../domain/overtime_day.dart';
import '../../domain/overtime_format.dart';

/// Tab "Summary" — lembur yang sudah terjadi bulan ini (realisasi dari
/// absensi): total jam, jumlah hari, dan daftar per hari.
class OvertimeSummaryTab extends StatefulWidget {
  const OvertimeSummaryTab({super.key, required this.days});

  /// Semua hari lembur yang diketahui; difilter per bulan di sini.
  final List<OvertimeDay> days;

  @override
  State<OvertimeSummaryTab> createState() => _OvertimeSummaryTabState();
}

class _OvertimeSummaryTabState extends State<OvertimeSummaryTab> {
  late DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);

  bool get _isCurrentMonth {
    final now = DateTime.now();
    return _month.year == now.year && _month.month == now.month;
  }

  void _shiftMonth(int delta) {
    setState(() => _month = DateTime(_month.year, _month.month + delta));
  }

  List<OvertimeDay> get _daysInMonth {
    final result = [
      for (final day in widget.days)
        if (day.date.year == _month.year && day.date.month == _month.month) day,
    ];
    result.sort((a, b) => a.date.compareTo(b.date));
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final days = _daysInMonth;
    final totalMinutes = days.fold<int>(0, (sum, day) => sum + day.minutes);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _TotalsCard(totalMinutes: totalMinutes, dayCount: days.length),
          const SizedBox(height: 20),
          Row(
            children: [
              _MonthArrow(icon: Icons.chevron_left, onTap: () => _shiftMonth(-1)),
              SizedBox(
                width: 130,
                child: Text(
                  DateFormat('MMMM yyyy', 'en_US').format(_month),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.text,
                  ),
                ),
              ),
              _MonthArrow(
                icon: Icons.chevron_right,
                onTap: _isCurrentMonth ? null : () => _shiftMonth(1),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (days.isEmpty)
            const _EmptyMonth()
          else
            AppCard(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (var i = 0; i < days.length; i++) ...[
                    if (i > 0) const Divider(height: 1, color: AppColors.border),
                    _DayRow(day: days[i]),
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
      ),
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
                  '${formatClock(day.checkIn)} – ${formatClock(day.checkOut)} · Shift ${day.shift}',
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
