import '../../absensi/domain/attendance_day.dart';
import '../../absensi/domain/attendance_month.dart';
import '../../absensi/domain/attendance_summary.dart';
import 'department_attendance_demo_data.dart';
import 'department_attendance_entry.dart';
import 'department_attendance_status.dart';

/// Data contoh detail bulanan satu karyawan — dipakai sampai API kehadiran
/// per karyawan tersedia.
///
/// Tiap tanggal dibangun dari [DepartmentAttendanceDemoData.forDate], jadi apa
/// yang tampil di kalender selalu sama dengan yang tampil di daftar hari itu
/// (mis. yang "Late 14m" hari ini juga "Telat 14m" di kalendernya).
class EmployeeAttendanceDemoData {
  EmployeeAttendanceDemoData._();

  static const _shiftCode = 'A';
  static const _shiftTime = '08:00–16:00';

  /// Teks jam untuk hari ini bila karyawan belum punya jam masuk. Dipakai
  /// juga untuk membedakannya dari yang sudah masuk saat menghitung ringkasan.
  static const notCheckedInText = 'Belum check-in';

  static AttendanceMonth month({
    required String employeeId,
    required DateTime month,
    required DateTime today,
  }) {
    final todayOnly = DateTime(today.year, today.month, today.day);
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final days = [
      for (var d = 1; d <= daysInMonth; d++)
        _day(employeeId, DateTime(month.year, month.month, d), todayOnly),
    ];
    return AttendanceMonth(days: days, summary: _summary(days));
  }

  static AttendanceDay _day(String employeeId, DateTime date, DateTime today) {
    final isWeekend =
        date.weekday == DateTime.saturday || date.weekday == DateTime.sunday;

    // Belum terjadi: hanya jadwal shift (akhir pekan tanpa shift).
    if (date.isAfter(today)) {
      return isWeekend
          ? AttendanceDay(date: date, status: AttendanceDayStatus.terjadwal)
          : AttendanceDay(
              date: date,
              status: AttendanceDayStatus.terjadwal,
              shiftCode: _shiftCode,
              shiftTimeRange: _shiftTime,
            );
    }

    final entry = _find(
      DepartmentAttendanceDemoData.forDate(date, today: today),
      employeeId,
    );
    if (entry == null) {
      return AttendanceDay(
        date: date,
        status: AttendanceDayStatus.liburHari,
        noteText: 'Hari libur',
      );
    }

    final isToday = date == today;
    final clockIn = entry.clockIn;
    // Jam pulang contoh, deterministik per tanggal.
    final clockOut = '16:${(date.day % 6).toString().padLeft(2, '0')}';
    final timeText = clockIn == null
        ? null
        : (isToday ? '$clockIn — Berlangsung' : '$clockIn – $clockOut');

    switch (entry.status) {
      case DepartmentAttendanceStatus.hadir:
        return AttendanceDay(
          date: date,
          status: isToday
              ? AttendanceDayStatus.berlangsung
              : AttendanceDayStatus.tepatWaktu,
          shiftCode: _shiftCode,
          shiftTimeRange: _shiftTime,
          timeText: timeText,
          badgeLabel: isToday ? null : 'Tepat waktu',
        );
      case DepartmentAttendanceStatus.terlambat:
        return AttendanceDay(
          date: date,
          status: AttendanceDayStatus.terlambat,
          shiftCode: _shiftCode,
          shiftTimeRange: _shiftTime,
          timeText: timeText,
          badgeLabel: 'Telat ${entry.lateMinutes ?? 0}m',
        );
      case DepartmentAttendanceStatus.belumCheckIn:
        // Hari ini: shift sudah mulai tapi belum ada jam masuk. Hari lampau:
        // tidak ada jam masuk sama sekali = tidak hadir.
        // Belum ada status "tidak hadir" di AttendanceDayStatus, jadi hari
        // lampau memakai liburHari (titik abu-abu) dengan catatan.
        return isToday
            ? AttendanceDay(
                date: date,
                status: AttendanceDayStatus.berlangsung,
                shiftCode: _shiftCode,
                shiftTimeRange: _shiftTime,
                timeText: notCheckedInText,
              )
            : AttendanceDay(
                date: date,
                status: AttendanceDayStatus.liburHari,
                shiftCode: _shiftCode,
                shiftTimeRange: _shiftTime,
                noteText: 'Tidak hadir',
              );
      case DepartmentAttendanceStatus.cuti:
        return AttendanceDay(
          date: date,
          status: AttendanceDayStatus.liburHari,
          noteText: entry.leaveLabel ?? 'Cuti',
        );
    }
  }

  static DepartmentAttendanceEntry? _find(
    List<DepartmentAttendanceEntry> entries,
    String id,
  ) {
    for (final e in entries) {
      if (e.id == id) return e;
    }
    return null;
  }

  static AttendanceSummary _summary(List<AttendanceDay> days) {
    var present = 0;
    var late = 0;
    for (final d in days) {
      switch (d.status) {
        case AttendanceDayStatus.tepatWaktu:
          present++;
        case AttendanceDayStatus.terlambat:
          present++;
          late++;
        case AttendanceDayStatus.berlangsung:
          if (d.timeText != notCheckedInText) present++;
        case AttendanceDayStatus.lembur:
          present++;
        case AttendanceDayStatus.liburHari:
        case AttendanceDayStatus.terjadwal:
          break;
      }
    }
    // Data lembur belum ada di data contoh departemen.
    return AttendanceSummary(present: present, late: late, overtimeHrs: 0);
  }
}
