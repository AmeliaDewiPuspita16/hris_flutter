/// Menulis angka meter gaya Indonesia: titik sebagai pemisah ribuan, koma
/// untuk pecahan (maksimal dua digit). Contoh: 19303 -> "19.303",
/// 12.5 -> "12,5".
///
/// Sengaja tanpa paket `intl`: formatnya sederhana dan tetap sama di semua
/// locale perangkat, sama seperti di web.
String formatMeterValue(num value) {
  final negative = value < 0;
  final rounded = (value.abs() * 100).round() / 100;
  final whole = rounded.truncate();
  final cents = ((rounded - whole) * 100).round();

  final digits = whole.toString();
  final grouped = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) grouped.write('.');
    grouped.write(digits[i]);
  }

  var text = grouped.toString();
  if (cents > 0) {
    final decimals = cents.toString().padLeft(2, '0').replaceFirst(RegExp(r'0$'), '');
    text = '$text,$decimals';
  }
  return negative ? '-$text' : text;
}

/// Membaca isian angka dari petugas.
///
/// Koma atau titik diterima sebagai pemisah desimal, dan pemisah ribuan
/// TIDAK dikenal: "34650" -> 34650, "12,5" -> 12.5. Null bila bukan angka
/// yang sah (kosong, huruf, negatif, atau lebih dari satu pemisah).
///
/// Kalau petugas menyalin gaya tampilan ("34.650"), hasilnya terbaca 34,65 —
/// dan [lowerThanPreviousWarning] memperingatkannya karena lebih kecil dari
/// angka sebelumnya, jadi salah ketik jenis ini tidak lolos diam-diam.
num? parseMeterInput(String text) {
  var cleaned = text.trim().replaceAll(',', '.');
  if (cleaned.endsWith('.')) cleaned = cleaned.substring(0, cleaned.length - 1);
  if (!RegExp(r'^\d+(\.\d+)?$').hasMatch(cleaned)) return null;
  return num.tryParse(cleaned);
}

/// Alasan isian [text] ditolak, atau null bila sah.
///
/// Hanya soal BENTUK: wajib diisi dan harus angka. Aturan "tidak boleh lebih
/// kecil dari angka sebelumnya" tidak ada di dokumen API, dan meter yang
/// diganti atau di-reset bisa sah — itu ditangani [lowerThanPreviousWarning]
/// sebagai peringatan, bukan penolakan.
String? validateMeterInput(String text) {
  if (text.trim().isEmpty) return 'Current value is required.';
  if (parseMeterInput(text) == null) return 'Enter a valid number.';
  return null;
}

/// Peringatan (BUKAN penolakan) bila angka di [text] lebih kecil dari
/// [previous]; null bila tidak ada yang perlu diperingatkan.
///
/// Menangkap salah ketik seperti "34.650" yang terbaca 34,65 — petugas
/// diminta memeriksa, dan boleh lanjut bila meternya memang diganti/di-reset.
String? lowerThanPreviousWarning(String text, {num? previous}) {
  final value = parseMeterInput(text);
  if (value == null || previous == null || value >= previous) return null;
  return 'Lower than the previous value (${formatMeterValue(previous)}). '
      'Check the digits, or continue if the meter was replaced or reset.';
}
