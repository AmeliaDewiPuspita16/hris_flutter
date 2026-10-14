import '../../../core/utils/json_value.dart';
import 'overtime_day.dart';

/// Realisasi lembur satu bulan — isi `data` dari
/// `GET /api/portal/apps/hris/overtime?month=YYYY-MM`.
class OvertimeMonth {
  const OvertimeMonth({
    required this.totalMinutes,
    required this.daysWithOvertime,
    required this.days,
  });

  /// Total dan jumlah hari diambil dari `summary` server; bila tidak ada
  /// dihitung dari `days[]`. Hari berlembur 0 menit dibuang dan daftar
  /// diurutkan dari tanggal paling awal.
  factory OvertimeMonth.fromJson(Map<String, dynamic> data) {
    final days = <OvertimeDay>[];

    final rawDays = data['days'];
    if (rawDays is List) {
      for (final raw in rawDays.whereType<Map<String, dynamic>>()) {
        final day = OvertimeDay.tryFromJson(raw);
        if (day != null && day.minutes > 0) days.add(day);
      }
    }
    days.sort((a, b) => a.date.compareTo(b.date));

    final rawSummary = data['summary'];
    final summary = rawSummary is Map<String, dynamic> ? rawSummary : null;

    final totalMinutes = summary != null && summary['total_overtime_hours'] != null
        ? (doubleOrZero(summary['total_overtime_hours']) * 60).round()
        : days.fold<int>(0, (sum, day) => sum + day.minutes);

    final dayCount = summary != null && summary['days_with_overtime'] != null
        ? amountOrZero(summary['days_with_overtime'])
        : days.length;

    return OvertimeMonth(
      totalMinutes: totalMinutes,
      daysWithOvertime: dayCount,
      days: days,
    );
  }

  final int totalMinutes;
  final int daysWithOvertime;
  final List<OvertimeDay> days;
}
