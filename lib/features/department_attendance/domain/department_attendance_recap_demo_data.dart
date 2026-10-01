import 'department_attendance_demo_data.dart';
import 'department_attendance_entry.dart';
import 'department_attendance_recap.dart';
import 'department_attendance_status.dart';

class _Counts {
  int late = 0;
  int absent = 0;
  int leave = 0;
}

/// Data contoh rekap bulanan — dipakai sampai API rekap tersedia.
///
/// Dihitung dengan menjumlahkan [DepartmentAttendanceDemoData.forDate] untuk
/// tiap hari kerja, jadi angkanya selalu cocok dengan daftar harian dan
/// kalender detail karyawan.
class DepartmentAttendanceRecapDemoData {
  DepartmentAttendanceRecapDemoData._();

  static DepartmentAttendanceRecap forMonth(
    DateTime month, {
    required DateTime today,
  }) {
    final todayOnly = DateTime(today.year, today.month, today.day);
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;

    final roster = <String, DepartmentAttendanceEntry>{};
    final counts = <String, _Counts>{};
    var workingDays = 0;

    for (var d = 1; d <= daysInMonth; d++) {
      final date = DateTime(month.year, month.month, d);
      if (date.isAfter(todayOnly)) break;

      final entries = DepartmentAttendanceDemoData.forDate(
        date,
        today: todayOnly,
      );
      // Kosong = akhir pekan, bukan hari kerja.
      if (entries.isEmpty) continue;
      workingDays++;

      for (final e in entries) {
        roster.putIfAbsent(e.id, () => e);
        final c = counts.putIfAbsent(e.id, _Counts.new);
        switch (e.status) {
          case DepartmentAttendanceStatus.terlambat:
            c.late++;
          case DepartmentAttendanceStatus.belumCheckIn:
            // Hari ini masih bisa check-in, jadi belum dihitung tidak hadir.
            if (date != todayOnly) c.absent++;
          case DepartmentAttendanceStatus.cuti:
            c.leave++;
          case DepartmentAttendanceStatus.hadir:
            break;
        }
      }
    }

    return DepartmentAttendanceRecap(
      workingDays: workingDays,
      rows: [
        for (final entry in roster.values)
          DepartmentAttendanceRecapRow(
            entry: entry,
            lateCount: counts[entry.id]!.late,
            absentCount: counts[entry.id]!.absent,
            leaveCount: counts[entry.id]!.leave,
          ),
      ],
    );
  }
}
