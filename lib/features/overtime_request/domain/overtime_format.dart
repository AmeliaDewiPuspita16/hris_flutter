import 'package:flutter/material.dart';

/// Pemformat kecil untuk layar Overtime Request (teks berbahasa Inggris,
/// sama seperti layar Leave Request).

/// Selisih menit dari [start] ke [end] pada hari yang sama. Bernilai <= 0
/// bila [end] tidak lebih lambat dari [start].
int overtimeMinutesBetween(TimeOfDay start, TimeOfDay end) =>
    (end.hour * 60 + end.minute) - (start.hour * 60 + start.minute);

/// Contoh: 90 → "1h 30m", 120 → "2h", 45 → "45m".
String formatOvertimeDuration(int minutes) {
  final hours = minutes ~/ 60;
  final rest = minutes % 60;

  if (hours == 0) return '${rest}m';
  if (rest == 0) return '${hours}h';
  return '${hours}h ${rest}m';
}

/// Jam desimal untuk kartu ringkasan. Contoh: 270 → "4.5", 180 → "3".
String formatOvertimeHours(int minutes) {
  final hours = minutes / 60;
  return hours == hours.roundToDouble()
      ? hours.toStringAsFixed(0)
      : hours.toStringAsFixed(1);
}

String formatClock(DateTime time) =>
    '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';

String formatTimeOfDay(TimeOfDay time) =>
    '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
