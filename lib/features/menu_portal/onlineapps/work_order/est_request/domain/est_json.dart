/// Pembaca nilai JSON yang dipakai bersama oleh model-model EST.
///
/// Dipisah dari tiap model supaya aturan baca tanggal cukup ada di satu
/// tempat (sebelumnya `EstApprovalItem` punya salinan sendiri).
library;

const _months = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

/// `2026-08-31T16:27:14+08:00` -> `31 Aug 2026`.
///
/// Hanya 10 karakter pertama (yyyy-MM-dd) yang dibaca, JANGAN di-parse
/// penuh lalu `toLocal()`: zona waktu server (+07:00 / +08:00) bisa beda
/// dengan perangkat, dan request yang dibuat malam hari bisa bergeser ke
/// tanggal lain.
String estDate(Object? raw) {
  final text = '${raw ?? ''}';
  if (text.length < 10) return text;

  final date = DateTime.tryParse(text.substring(0, 10));
  if (date == null) return text;

  return '${date.day} ${_months[date.month - 1]} ${date.year}';
}

/// Angka opsional: `null`, teks kosong, atau teks bukan angka jadi `null`.
int? estOptionalInt(Object? raw) {
  if (raw is num) return raw.toInt();
  return int.tryParse('${raw ?? ''}');
}
