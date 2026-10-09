import 'attendance_day.dart';
import 'attendance_summary.dart';

/// Hasil satu kali muat Log Absensi: seluruh tanggal dalam satu bulan
/// (jadwal shift + realisasi kehadiran) beserta ringkasannya.
class AttendanceMonth {
  const AttendanceMonth({
    required this.days,
    required this.summary,
  });

  factory AttendanceMonth.fromJson(
    Map<String, dynamic> data, {
    required DateTime month,
  }) {
    final byDate = <String, AttendanceDay>{};

    final rawDays = data['days'];
    if (rawDays is List) {
      for (final raw in rawDays.whereType<Map<String, dynamic>>()) {
        final day = AttendanceDay.tryFromJson(raw);
        if (day != null) byDate[_key(day.date)] = day;
      }
    }

    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final days = [
      for (var d = 1; d <= daysInMonth; d++)
        byDate[_key(DateTime(month.year, month.month, d))] ??
            AttendanceDay(
              date: DateTime(month.year, month.month, d),
              status: AttendanceDayStatus.terjadwal,
            ),
    ];

    final summary = data['summary'];
    return AttendanceMonth(
      days: days,
      summary: summary is Map<String, dynamic>
          ? AttendanceSummary.fromJson(summary)
          : const AttendanceSummary(present: 0, late: 0, overtimeHrs: 0),
    );
  }

  static String _key(DateTime d) => '${d.year}-${d.month}-${d.day}';



  /// Satu entri per tanggal dalam bulan, urut dari tanggal 1 sampai akhir
  /// bulan (termasuk tanggal yang belum terjadi)
  final List<AttendanceDay> days;

  final AttendanceSummary summary;
}
