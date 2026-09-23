/// Ringkasan absensi 1 bulan, ditampilkan di kartu atas Log Absensi.
class AttendanceSummary {
  const AttendanceSummary({
    required this.present,
    required this.late,
    required this.overtimeHrs,
  });

  final int present;
  final int late;
  final int overtimeHrs;
}
