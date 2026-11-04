import '../../../core/utils/json_value.dart';
import 'attendance_day.dart';
import 'attendance_summary.dart';
import 'scheduled_shift.dart';

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
    Map<String, dynamic>? schedule,
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

    final shifts = _shiftsByDate(schedule);

    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final days = [
      for (var d = 1; d <= daysInMonth; d++)
        _weekendRule(
          _withOvertime(
            _withSchedule(
                byDate[_key(DateTime(month.year, month.month, d))],
                DateTime(month.year, month.month, d),
                shifts[_key(DateTime(month.year, month.month, d))]),
            overtimeMinutes,
          ),
        ),
    ];

    // Lembur akhir pekan shift N yang TIDAK tercatat di endpoint overtime
    // (lamanya diambil dari jam kerja) ikut dijumlahkan ke ringkasan, supaya
    // kartu "Overtime Hours" sama dengan badge di kalender.
    final weekendExtraMinutes = days
        .where((d) =>
            d.isNormalShiftWeekend &&
            d.status == AttendanceDayStatus.lembur &&
            (overtimeMinutes[_key(d.date)] ?? 0) <= 0)
        .fold<int>(0, (sum, d) => sum + d.overtimeMinutes);

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
    final totalOvertimeHrs = overtimeHrs + weekendExtraMinutes / 60;

    return AttendanceMonth(
      days: days,
      summary: AttendanceSummary(
        present: fromServer.present,
        late: lateDays,
        overtimeHrs: totalOvertimeHrs,
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

  /// Shift N hanya Senin–Jumat: kehadiran di Sabtu/Minggu dengan shift N
  /// dihitung lembur, bukan terlambat. Dijalankan SETELAH jadwal digabung,
  /// karena kode shift bisa baru diketahui dari endpoint jadwal. Hari yang
  /// belum selesai (berlangsung/terjadwal) dibiarkan.
  static AttendanceDay _weekendRule(AttendanceDay day) {
    final finished = day.status == AttendanceDayStatus.tepatWaktu ||
        day.status == AttendanceDayStatus.terlambat;
    if (!finished || !day.isNormalShiftWeekend) return day;

    return day.asWeekendOvertime();
  }

  /// jadwal shift per tanggal dari `days[]` endpoint shift. Item yang
  /// tanggal atau shift-nya tidak terbaca dilewati.
  static Map<String, ScheduledShift> _shiftsByDate(
    Map<String, dynamic>? schedule,
  ) {
    final result = <String, ScheduledShift>{};

    final rawDays = schedule?['days'];
    if (rawDays is! List) return result;

    for (final raw in rawDays.whereType<Map<String, dynamic>>()) {
      final date = dateOrNull(raw['date']);
      final rawShift = raw['shift'];
      if (date == null || rawShift is! Map<String, dynamic>) continue;

      final shift = ScheduledShift.tryFromJson(rawShift);
      if (shift != null) result[_key(date)] = shift;
    }
    return result;
  }

  /// Menggabungkan jadwal ke satu tanggal.
  /// - Tanggal tanpa realisasi (null): dibuat "terjadwal" dengan shiftnya,
  ///   atau "liburHari" bila jadwalnya off
  /// - Tanggal dengan realisasi: tidak diubah, kecuali shift-nya kosong
  ///   (jadwal dipakai sebagai cadangan)
  static AttendanceDay _withSchedule(
    AttendanceDay? actual,
    DateTime date,
    ScheduledShift? shift,
  ) {
    if (actual == null) {
      if (shift == null) {
        return AttendanceDay(date: date, status: AttendanceDayStatus.terjadwal);
      }
      if (shift.isOff) {
        return AttendanceDay(date: date, status: AttendanceDayStatus.liburHari);
      }
      return AttendanceDay(
          date: date,
          status: AttendanceDayStatus.terjadwal,
          shiftCode: shift.code,
          shiftTimeRange: shift.timeRange);
    }

    if (actual.shiftCode == null && shift != null && !shift.isOff) {
      return actual.withShift(code: shift.code, timeRange: shift.timeRange);
    }
    return actual;
  }
  

  static String _key(DateTime d) => '${d.year}-${d.month}-${d.day}';

  /// Satu entri per tanggal dalam bulan, urut dari tanggal 1 sampai akhir
  /// bulan (termasuk tanggal yang belum terjadi)
  final List<AttendanceDay> days;

  final AttendanceSummary summary;
}
