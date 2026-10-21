/// Teks lembur untuk layar Log Absensi (satuan: "h" = jam,
/// "m" = menit).

/// Jam desimal untuk kartu ringkasan. Contoh: 4.5 → "4.5h", 3.0 → "3h".
String overtimeHoursText(double hours) {
  final rounded = (hours * 10).round() / 10;
  final text = rounded == rounded.roundToDouble()
      ? rounded.toStringAsFixed(0)
      : rounded.toStringAsFixed(1);

  return '${text}h';
}

/// Durasi dari menit. Contoh: 90 → "1h 30m", 120 → "2h", 45 → "45m".
String overtimeDurationText(int minutes) {
  final hours = minutes ~/ 60;
  final rest = minutes % 60;

  if (hours == 0) return '${rest}m';
  if (rest == 0) return '${hours}h';
  return '${hours}h ${rest}m';
}
