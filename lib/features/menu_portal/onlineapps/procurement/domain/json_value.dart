/// Pembaca nilai JSON yang dipakai berulang oleh model-model EProcurement.
library;

/// String yang benar-benar berisi, atau null.
///
/// Server memakai `null` dan `""` bergantian untuk "kosong" — tanpa ini tiap
/// model harus memeriksa keduanya sendiri.
String? textOrNull(dynamic value) =>
    value is String && value.trim().isNotEmpty ? value : null;

/// Nominal rupiah sebagai int.
///
/// Server mengirimnya sebagai int, tapi angka besar bisa datang sebagai
/// double lewat JSON — dibulatkan supaya tidak berakhir jadi "2.9E9".
int amountOrZero(dynamic value) => switch (value) {
      int() => value,
      num() => value.round(),
      String() => int.tryParse(value) ?? 0,
      _ => 0,
    };

/// Bilangan bulat, atau [fallback] bila bentuknya lain.
int intOr(dynamic value, int fallback) => value is int ? value : fallback;

/// Tanggal dari string ISO, atau null bila kosong/tidak masuk akal.
///
/// `DateTime.tryParse` menormalkan tanggal mustahil alih-alih gagal:
/// "0000-00-00" — yang biasa dikirim MySQL untuk tanggal kosong — berubah
/// jadi 30 November tahun 0, bukan null. Untuk string tanggal polos hasilnya
/// diperiksa ulang supaya tanggal kosong benar-benar jadi null.
///
/// Pemeriksaan itu sengaja dilewati untuk string bertanda waktu
/// ("2026-08-28T15:03:11+07:00"): `DateTime.parse` mengubahnya ke UTC, jadi
/// membandingkan tanggalnya bisa meleset satu hari untuk jam dini hari.
DateTime? dateOrNull(dynamic value) {
  final text = textOrNull(value);
  if (text == null) return null;

  final parsed = DateTime.tryParse(text);
  if (parsed == null) return null;

  final isPlainDate = !text.contains('T') && text.length == 10;
  if (isPlainDate && _asPlainDate(parsed) != text) return null;

  return parsed;
}

String _asPlainDate(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-'
    '${date.month.toString().padLeft(2, '0')}-'
    '${date.day.toString().padLeft(2, '0')}';
