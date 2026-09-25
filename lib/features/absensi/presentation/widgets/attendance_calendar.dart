import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/attendance_day.dart';

/// Grid kalender Log Absensi.
///
/// - Tanggal yang sudah berlalu/berlangsung: border tipis + titik kecil
///   berwarna sesuai status kehadiran.
/// - Tanggal yang belum terjadi: border tipis tanpa titik warna (belum ada
///   realisasi), tapi kode shift tetap muncul di pojok karena jadwalnya
///   sudah diketahui dari HR.
/// - Tap tanggal mana pun untuk melihat detailnya lewat [onDateSelected].
class AttendanceCalendar extends StatelessWidget {
  const AttendanceCalendar({
    super.key,
    required this.month,
    required this.days,
    required this.selectedDate,
    required this.onDateSelected,
  });

  final DateTime month;
  final List<AttendanceDay> days;
  final DateTime? selectedDate;
  final ValueChanged<DateTime> onDateSelected;

  static const _weekdayLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  @override
  Widget build(BuildContext context) {
    // Senin jadi kolom pertama.
    final firstOfMonth = DateTime(month.year, month.month, 1);
    final leadingBlanks = firstOfMonth.weekday - 1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            for (final label in _weekdayLabels)
              Expanded(
                child: Center(
                  child: Text(
                    label,
                    style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 4),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            mainAxisSpacing: 4,
            crossAxisSpacing: 4,
            childAspectRatio: 1,
          ),
          itemCount: leadingBlanks + days.length,
          itemBuilder: (context, index) {
            if (index < leadingBlanks) return const SizedBox.shrink();

            final day = days[index - leadingBlanks];
            final isSelected = selectedDate != null && day.isSameDay(selectedDate!);

            return _DayCell(
              day: day,
              isSelected: isSelected,
              onTap: () => onDateSelected(day.date),
            );
          },
        ),
      ],
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.day,
    required this.isSelected,
    required this.onTap,
  });

  final AttendanceDay day;
  final bool isSelected;
  final VoidCallback onTap;

  /// Null berarti belum ada realisasi untuk tanggal ini (jadi tidak ada
  /// titik yang ditampilkan) — lihat dokumentasi kelas [AttendanceCalendar].
  Color? get _dotColor {
    switch (day.status) {
      case AttendanceDayStatus.tepatWaktu:
        return AppColors.present;
      case AttendanceDayStatus.terlambat:
        return AppColors.rejected;
      case AttendanceDayStatus.lembur:
        return AppColors.overtime;
      case AttendanceDayStatus.liburHari:
        return AppColors.neutral;
      case AttendanceDayStatus.berlangsung:
        return AppColors.pending;
      case AttendanceDayStatus.terjadwal:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final dotColor = _dotColor;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: isSelected ? 1.4 : 0.6,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${day.date.day}',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                  color: AppColors.text,
                ),
              ),
              const SizedBox(height: 3),
              SizedBox(
                height: 4,
                width: 4,
                child: dotColor == null
                    ? null
                    : DecoratedBox(
                        decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
