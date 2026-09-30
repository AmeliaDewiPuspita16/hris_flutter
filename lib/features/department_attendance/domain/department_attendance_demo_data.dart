import 'department_attendance_entry.dart';
import 'department_attendance_status.dart';

class _Person {
  const _Person(this.id, this.name, this.position);

  final String id;
  final String name;
  final String position;
}

/// Data contoh Department Attendance Log — dipakai sampai API kehadiran per
/// departemen tersedia. Untuk tanggal yang sudah lewat, statusnya dibangkitkan
/// dari tanggal secara deterministik (hasilnya selalu sama untuk tanggal yang
/// sama), supaya pindah-pindah hari di layar terasa hidup.
class DepartmentAttendanceDemoData {
  DepartmentAttendanceDemoData._();

  static const departmentName = 'IT & Media';

  // Kantor hanya punya satu shift (A). Jamnya mengikuti shift A yang sudah
  // dibuat di Attendance Log; nanti diganti data API.
  static const _shiftCode = 'A';
  static const _shiftTime = '08:00–16:00';

  // Jabatan hanya contoh.
  static const _people = [
    _Person('0774', 'Ari Putra', 'IT Solution'),
    _Person('0801', 'Amelia', 'Intern'),
    _Person('0035', 'Aditya Yudha', 'IT Solution'),
    _Person('0812', 'Marsha', 'IT Media'),
    _Person('0823', 'Surya Asmara', 'IT Solution'),
    _Person('0047', 'Rayhan', 'IT Infrastructure'),
    _Person('0788', 'Noval', 'IT Media'),
    _Person('0834', 'Muhammad Fadli', 'IT Infra'),
    _Person('0845', 'Fanny Saputra', 'Intern'),
    _Person('0800', 'Intan', 'Intern'),
  ];

  /// Kehadiran satu departemen pada [date]. Kosong untuk akhir pekan dan
  /// tanggal setelah [today] (belum ada realisasi).
  static List<DepartmentAttendanceEntry> forDate(
    DateTime date, {
    required DateTime today,
  }) {
    final day = DateTime(date.year, date.month, date.day);
    final todayOnly = DateTime(today.year, today.month, today.day);
    final isWeekend =
        day.weekday == DateTime.saturday || day.weekday == DateTime.sunday;
    if (isWeekend || day.isAfter(todayOnly)) return const [];

    final isToday = day == todayOnly;
    return [
      for (var i = 0; i < _people.length; i++)
        isToday ? _forToday(_people[i], i) : _forPastDay(_people[i], i, day),
    ];
  }

  static DepartmentAttendanceEntry _forToday(_Person p, int index) {
    switch (p.id) {
      case '0047':
        return _entry(p, DepartmentAttendanceStatus.belumCheckIn);
      case '0774':
        return _entry(
          p,
          DepartmentAttendanceStatus.terlambat,
          clockIn: '08:14',
          lateMinutes: 14,
        );
      case '0823':
        return _entry(
          p,
          DepartmentAttendanceStatus.terlambat,
          clockIn: '08:32',
          lateMinutes: 32,
        );
      case '0035':
        return _entry(
          p,
          DepartmentAttendanceStatus.cuti,
          leaveLabel: 'Annual leave',
        );
      default:
        return _entry(
          p,
          DepartmentAttendanceStatus.hadir,
          clockIn: '07:${(45 + index).toString().padLeft(2, '0')}',
        );
    }
  }

  static DepartmentAttendanceEntry _forPastDay(
    _Person p,
    int index,
    DateTime day,
  ) {
    final seed = day.day + day.month * 31;
    final k = (seed + index * 7) % 12;

    if (k == 0) {
      final minutes = 5 + (seed + index * 3) % 40;
      return _entry(
        p,
        DepartmentAttendanceStatus.terlambat,
        clockIn: '08:${minutes.toString().padLeft(2, '0')}',
        lateMinutes: minutes,
      );
    }
    if (k == 1) {
      return _entry(
        p,
        DepartmentAttendanceStatus.cuti,
        leaveLabel: 'Annual leave',
      );
    }
    if (k == 2 && index.isEven) {
      return _entry(p, DepartmentAttendanceStatus.belumCheckIn);
    }
    return _entry(
      p,
      DepartmentAttendanceStatus.hadir,
      clockIn: '07:${(45 + (seed + index) % 14).toString().padLeft(2, '0')}',
    );
  }

  static DepartmentAttendanceEntry _entry(
    _Person p,
    DepartmentAttendanceStatus status, {
    String? clockIn,
    int? lateMinutes,
    String? leaveLabel,
  }) {
    return DepartmentAttendanceEntry(
      id: p.id,
      name: p.name,
      position: p.position,
      status: status,
      shiftCode: _shiftCode,
      shiftTimeRange: _shiftTime,
      clockIn: clockIn,
      lateMinutes: lateMinutes,
      leaveLabel: leaveLabel,
    );
  }
}
