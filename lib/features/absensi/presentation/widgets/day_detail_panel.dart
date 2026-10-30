import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/attendance_day.dart';
import '../../domain/overtime_text.dart';

/// Panel yang menampilkan detail satu tanggal terpilih dari
/// [AttendanceCalendar] — jam kerja/realisasi, shift, dan badge status.
class DayDetailPanel extends StatelessWidget {
  const DayDetailPanel({super.key, required this.day});

  final AttendanceDay? day;

  static const _months = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  @override
  Widget build(BuildContext context) {
    final day = this.day;
    if (day == null) {
      return Text(
        'Select a date to see its details.',
        style: TextStyle(fontSize: 13, color: AppColors.textMuted),
      );
    }

    final dateLabel = '${day.date.day} ${_months[day.date.month - 1]}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          dateLabel,
          style: TextStyle(
              fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.text),
        ),
        const SizedBox(height: 6),
        if (day.status == AttendanceDayStatus.terjadwal)
          _buildScheduledOnly(day)
        else if (day.status == AttendanceDayStatus.liburHari &&
            day.timeText == null)
          _buildDayOff()
        else
          _buildRealized(day),
      ],
    );
  }

  Widget _buildDayOff() {
    return Text(
      'Day Off',
      style: TextStyle(
          fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.text),
    );
  }

  Widget _buildScheduledOnly(AttendanceDay day) {
    if (day.shiftCode == null) {
      return Text(
        // 'Hari libur bersama',
        'No attendance or schedule data for this date yet.',
        style: TextStyle(fontSize: 13, color: AppColors.textMuted),
      );
    }

    final now = DateTime.now();

    final isPast = day.date.isBefore(DateTime(now.year, now.month, now.day));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Scheduled shift ${day.shiftCode} · ${day.shiftTimeRange}',
          style: TextStyle(
              fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.text),
        ),
        const SizedBox(height: 2),
        Text(
          isPast ? 'No attendance recorded' : 'Not started yet',
          style: TextStyle(fontSize: 12, color: AppColors.textMuted),
        ),
      ],
    );
  }

  Widget _buildRealized(AttendanceDay day) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          day.timeText ?? day.noteText ?? '-',
          style: TextStyle(
              fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.text),
        ),
        if (day.shiftCode != null) ...[
          const SizedBox(height: 2),
          Text(
            day.shiftTimeRange == null
                ? 'Shift ${day.shiftCode}'
                : 'Shift ${day.shiftCode} · ${day.shiftTimeRange}',
            style: TextStyle(fontSize: 12, color: AppColors.textMuted),
          ),
        ],
        if (day.badgeLabel != null || day.hasOvertime) ...[
          const SizedBox(height: 8),
          // Lembur jadi badge tambahan di samping status (Tepat waktu /
          // Terlambat), bukan menggantikannya.
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              if (day.badgeLabel != null)
                _StatusBadge(status: day.status, label: day.badgeLabel!),
              if (day.hasOvertime)
                _StatusBadge(
                  status: AttendanceDayStatus.lembur,
                  label:
                      'Overtime ${overtimeDurationText(day.overtimeMinutes)}',
                ),
            ],
          ),
        ],
      ],
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status, required this.label});

  final AttendanceDayStatus status;
  final String label;

  ({Color fg, Color bg}) get _colors {
    switch (status) {
      case AttendanceDayStatus.tepatWaktu:
      case AttendanceDayStatus.berlangsung:
        return (fg: AppColors.present, bg: AppColors.presentBg);
      case AttendanceDayStatus.lembur:
        return (fg: AppColors.overtime, bg: AppColors.overtimeBg);
      case AttendanceDayStatus.terlambat:
        return (fg: AppColors.rejected, bg: AppColors.rejectedBg);
      case AttendanceDayStatus.liburHari:
      case AttendanceDayStatus.terjadwal:
        return (fg: AppColors.neutral, bg: AppColors.neutralBg);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = _colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration:
          BoxDecoration(color: c.bg, borderRadius: BorderRadius.circular(6)),
      child: Text(
        label,
        style: TextStyle(
            fontSize: 9.5,
            fontWeight: FontWeight.w800,
            color: c.fg,
            letterSpacing: 0.2),
      ),
    );
  }
}
