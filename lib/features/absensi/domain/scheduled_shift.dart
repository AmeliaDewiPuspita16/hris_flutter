import '../../../core/utils/json_value.dart';

/// jadwal shift satu tanggal dari 'GET .../hris/shift?month='
class ScheduledShift {
  const ScheduledShift(
      {required this.code, required this.isOff, this.timeRange});

  /// kode singkat, mis. "N". Server mengirim "N - Normal Shift"; yang
  /// dipakai hanya bagian sebelum " - " supaya sama dengan kode shift dari
  /// data realisasi (lihat AttendanceDay._parseShift).
  final String code;

  /// rentang jam, mis. "08:00-17:00". Bisa null.
  final String? timeRange;

  /// true bila tanggal itu hari libur menurut jadwal
  final bool isOff;

  /// Null bila objek shift-nya kosong atau tidak punya kode
  static ScheduledShift? tryFromJson(Map<String, dynamic> json) {
    final rawCode = textOrNull(json['code']);
    if (rawCode == null) return null;

    final start = textOrNull(json['start_time']);
    final end = textOrNull(json['end_time']);

    return ScheduledShift(
      code: rawCode.split(' - ').first.trim(),
      // utamakan time_range dari server; kalau kosongm rakit dari
      // start_time & end_time
      timeRange: textOrNull(json['time_range'])??
          (start != null && end != null ? '$start–$end' : null),
      isOff: json['is_off'] == true,
    );
  }
}
