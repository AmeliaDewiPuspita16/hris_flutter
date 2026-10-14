import '../../../core/utils/json_value.dart';
import 'attendance_day.dart';
import 'attendance_summary.dart';

/// Hasil satu kali muat Log Absensi: seluruh tanggal dalam satu bulan
/// (jadwal shift + realisasi kehadiran) beserta ringkasannya.
class AttendanceMonth {
  const AttendanceMonth({
    required this.days,
    required this.summary,
  });

  /// [overtime] = isi `data` dari `GET .../hris/overtime?month=`. Null bila
  /// endpoint itu gagal dimuat: absensi tetap tampil, hanya tanpa lembur
  /// per hari, dan jam lembur kembali memakai angka dari [data].
  factory AttendanceMonth.fromJson(
    Map<String, dynamic> data, {
    required DateTime month,
    Map<String, dynamic>? overtime,
  }) {
    final byDate = <String, AttendanceDay>{};

    final rawDays = data['days'];
    if (rawDays is List) {
      for (final raw in rawDays.whereType<Map<String, dynamic>>()) {
        final day = AttendanceDay.tryFromJson(raw);
        if (day != null) byDate[_key(day.date)] = day;
      }
    }

    final overtimeMinutes = _overtimeMinutesByDate(overtime);

    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final days = [
      for (var d = 1; d <= daysInMonth; d++)
        _withOvertime(
          byDate[_key(DateTime(month.year, month.month, d))] ??
              AttendanceDay(
                date: DateTime(month.year, month.month, d),
                status: AttendanceDayStatus.terjadwal,
              ),
          overtimeMinutes,
        ),
    ];

    final raw = data['summary'];
    final fromServer = raw is Map<String, dynamic>
        ? AttendanceSummary.fromJson(raw)
        : const AttendanceSummary(present: 0, late: 0, overtimeHrs: 0);

    // "Terlambat" dihitung dari hari-hari di atas (aturan: jam masuk lewat
    // jam mulai shift), bukan memakai `late_days` dari server, supaya angkanya
    // sama dengan kalender. Hadir dan lembur tetap dari server.
    final lateDays =
        days.where((d) => d.status == AttendanceDayStatus.terlambat).length;

    // Jam lembur: total dari endpoint overtime (akurat, pecahan) bila ada;
    // kalau tidak, cadangan dari endpoint attendance.
    final overtimeSummary = overtime?['summary'];
    final overtimeHrs = overtimeSummary is Map<String, dynamic> &&
            overtimeSummary['total_overtime_hours'] != null
        ? doubleOrZero(overtimeSummary['total_overtime_hours'])
        : fromServer.overtimeHrs;

    return AttendanceMonth(
      days: days,
      summary: AttendanceSummary(
        present: fromServer.present,
        late: lateDays,
        overtimeHrs: overtimeHrs,
      ),
    );
  }

  /// Menit lembur per tanggal dari `days[]` endpoint overtime. Item yang
  /// tanggalnya tidak terbaca dilewati. Bila `overtime_minutes` kosong,
  /// dihitung dari `overtime_hours`.
  static Map<String, int> _overtimeMinutesByDate(
    Map<String, dynamic>? overtime,
  ) {
    final result = <String, int>{};

    final rawDays = overtime?['days'];
    if (rawDays is! List) return result;

    for (final raw in rawDays.whereType<Map<String, dynamic>>()) {
      final date = dateOrNull(raw['date']);
      if (date == null) continue;

      final minutes = raw['overtime_minutes'] != null
          ? amountOrZero(raw['overtime_minutes'])
          : (doubleOrZero(raw['overtime_hours']) * 60).round();

      result[_key(date)] = minutes;
    }
    return result;
  }

  /// Lembur hanya ditempel ke hari yang sudah ada realisasinya; tanggal
  /// yang belum terjadi (terjadwal) tidak punya lembur.
  static AttendanceDay _withOvertime(
    AttendanceDay day,
    Map<String, int> overtimeMinutes,
  ) {
    final minutes = overtimeMinutes[_key(day.date)] ?? 0;
    if (minutes <= 0 || day.isScheduledOnly) return day;

    return day.withOvertime(minutes);
  }

  static String _key(DateTime d) => '${d.year}-${d.month}-${d.day}';

  /// Satu entri per tanggal dalam bulan, urut dari tanggal 1 sampai akhir
  /// bulan (termasuk tanggal yang belum terjadi)
  final List<AttendanceDay> days;

  final AttendanceSummary summary;
}
