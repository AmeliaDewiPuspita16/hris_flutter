/// Teks lembur untuk layar Log Absensi (mengikuti bahasa layar ini: "j" =
/// jam, "m" = menit).

/// Jam desimal untuk kartu ringkasan. Contoh: 4.5 → "4,5j", 3.0 → "3j".
String overtimeHoursText(double hours) {
  final rounded = (hours * 10).round() / 10;
  final text = rounded == rounded.roundToDouble()
      ? rounded.toStringAsFixed(0)
      : rounded.toStringAsFixed(1).replaceAll('.', ',');

  return '${text}j';
}

/// Durasi dari menit. Contoh: 90 → "1j 30m", 120 → "2j", 45 → "45m".
String overtimeDurationText(int minutes) {
  final hours = minutes ~/ 60;
  final rest = minutes % 60;

  if (hours == 0) return '${rest}m';
  if (rest == 0) return '${hours}j';
  return '${hours}j ${rest}m';
}
