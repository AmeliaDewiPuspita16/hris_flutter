import 'attendance_entry.dart';
import 'attendance_summary.dart';

/// Hasil satu kali muat Log Absensi: daftar entri harian beserta
/// ringkasannya, untuk bulan yang sama.
class AttendanceMonth {
  const AttendanceMonth({
    required this.entries,
    required this.summary,
  });

  final List<AttendanceEntry> entries;
  final AttendanceSummary summary;
}
