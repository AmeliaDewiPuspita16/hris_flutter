import 'department_attendance_entry.dart';

/// Satu baris rekap bulanan: hitungan kehadiran seorang karyawan dalam satu
/// bulan. [entry] hanya dipakai untuk identitas (id, nama, jabatan) — status
/// di dalamnya tidak bermakna di sini.
class DepartmentAttendanceRecapRow {
  const DepartmentAttendanceRecapRow({
    required this.entry,
    required this.lateCount,
    required this.absentCount,
    required this.leaveCount,
  });

  final DepartmentAttendanceEntry entry;

  /// Hari masuk terlambat.
  final int lateCount;

  /// Hari kerja yang sudah lewat tanpa jam masuk dan tanpa cuti.
  final int absentCount;

  /// Hari cuti/izin.
  final int leaveCount;
}

/// Rekap kehadiran satu departemen dalam satu bulan.
class DepartmentAttendanceRecap {
  const DepartmentAttendanceRecap({
    required this.rows,
    required this.workingDays,
  });

  final List<DepartmentAttendanceRecapRow> rows;

  /// Jumlah hari kerja yang sudah berjalan di bulan ini (akhir pekan dan
  /// hari setelah "hari ini" tidak dihitung).
  final int workingDays;
}
