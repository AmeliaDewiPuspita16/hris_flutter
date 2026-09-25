import 'attendance_day.dart';
import 'attendance_summary.dart';

/// Hasil satu kali muat Log Absensi: seluruh tanggal dalam satu bulan
/// (jadwal shift + realisasi kehadiran) beserta ringkasannya.
class AttendanceMonth {
  const AttendanceMonth({
    required this.days,
    required this.summary,
  });

  /// Satu entri per tanggal dalam bulan, urut dari tanggal 1 sampai akhir
  /// bulan (termasuk tanggal yang belum terjadi, karena jadwal shift-nya
  /// sudah diketahui lebih dulu).
  final List<AttendanceDay> days;

  final AttendanceSummary summary;
}
