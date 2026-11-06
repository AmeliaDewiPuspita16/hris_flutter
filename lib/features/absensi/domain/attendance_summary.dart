import '../../../core/utils/json_value.dart';

/// Ringkasan absensi 1 bulan, ditampilkan di kartu atas Log Absensi.
class AttendanceSummary {
  const AttendanceSummary({
    required this.present,
    required this.late,
    required this.overtimeHrs,
  });

  /// membaca objek 'summary' dari respons attendance.
  ///
  /// 'overtime_hours' sumbernya sama dengan endpoint overtime (pengajuan yang
  /// disetujui) dan null bila HRIS gagal menyediakannya. Nilai dari endpoint
  /// overtime menimpanya di [AttendanceMonth.fromJson]; angka ini jadi cadangan
  /// saat endpoint overtime gagal dimuat.
  factory AttendanceSummary.fromJson(Map<String, dynamic> json) {
    return AttendanceSummary(
      present: amountOrZero(json['present_days']),
      late: amountOrZero(json['late_days']),
      overtimeHrs: doubleOrZero(json['overtime_hours']),
    );
  }

  final int present;
  final int late;
  /// Total jam lembur sebulan, bisa pecahan (mis. 4.5).
  final double overtimeHrs;
}
