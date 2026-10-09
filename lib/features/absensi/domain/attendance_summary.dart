import '../../../core/utils/json_value.dart';

/// Ringkasan absensi 1 bulan, ditampilkan di kartu atas Log Absensi.
class AttendanceSummary {
  const AttendanceSummary({
    required this.present,
    required this.late,
    required this.overtimeHrs,
  });

  /// membaca objek 'Summary' dari respons attendance.
  ///
  /// 'overtime_hours' dibulatkan karena model ini menyimpan int. kalau
  /// nanti server mengirim jam pecahan (mis. 4,5) dan ingin ditampilkan
  /// apa adanya, ubah [overtimeHrs] jadi double
  factory AttendanceSummary.fromJson(Map<String, dynamic> json) {
    return AttendanceSummary(
        present: amountOrZero(json['present_days']),
        late: amountOrZero(json['late_days']),
        overtimeHrs: amountOrZero(json['overtime_hours']));
  }

  final int present;
  final int late;
  final int overtimeHrs;
}
