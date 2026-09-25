import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/attendance_day.dart';

/// Panel yang menampilkan detail satu tanggal terpilih dari
/// [AttendanceCalendar] — jam kerja/realisasi, shift, dan badge status.
class DayDetailPanel extends StatelessWidget {
  const DayDetailPanel({super.key, required this.day});

  final AttendanceDay? day;

  static const _months = [
    'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
    'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember',
  ];

  @override
  Widget build(BuildContext context) {
    final day = this.day;
    if (day == null) {
      return const Text(
        'Pilih tanggal untuk melihat detailnya.',
        style: TextStyle(fontSize: 13, color: AppColors.textMuted),
      );
    }

    final dateLabel = '${day.date.day} ${_months[day.date.month - 1]}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          dateLabel,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.text),
        ),
        const SizedBox(height: 6),
        if (day.status == AttendanceDayStatus.terjadwal)
          _buildScheduledOnly(day)
        else
          _buildRealized(day),
      ],
    );
  }

  Widget _buildScheduledOnly(AttendanceDay day) {
    if (day.shiftCode == null) {
      return const Text(
        'Hari libur terjadwal.',
        style: TextStyle(fontSize: 13, color: AppColors.textMuted),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Terjadwal shift ${day.shiftCode} · ${day.shiftTimeRange}',
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.text),
        ),
        const SizedBox(height: 2),
        const Text(
          'Belum berlangsung',
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
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.text),
        ),
        if (day.shiftCode != null) ...[
          const SizedBox(height: 2),
          Text(
            'Shift ${day.shiftCode} · ${day.shiftTimeRange}',
            style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
          ),
        ],
        if (day.badgeLabel != null) ...[
          const SizedBox(height: 8),
          _StatusBadge(status: day.status, label: day.badgeLabel!),
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
      decoration: BoxDecoration(color: c.bg, borderRadius: BorderRadius.circular(6)),
      child: Text(
        label,
        style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w800, color: c.fg, letterSpacing: 0.2),
      ),
    );
  }
}
