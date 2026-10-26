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

/// `2026-10-23T16:11:06+07:00` -> `23 Oct 2026 · 16:11`.
///
/// Jam dibaca apa adanya dari teks (jam server), alasannya sama dengan
/// [estDate]. Teks tanpa bagian jam (mis. `2026-10-22`) hanya jadi tanggal.
String estDateTime(Object? raw) {
  final text = '${raw ?? ''}';
  final date = estDate(text);
  if (text.length < 16 || text[10] != 'T') return date;

  return '$date · ${text.substring(11, 16)}';
}

/// Angka opsional: `null`, teks kosong, atau teks bukan angka jadi `null`.
int? estOptionalInt(Object? raw) {
  if (raw is num) return raw.toInt();
  return int.tryParse('${raw ?? ''}');
}

/// HTML dari server -> teks biasa, atau `null` bila hasilnya kosong.
///
/// `working_method` dan `material_and_tools` ditulis tim EST lewat editor
/// teks, jadi isinya HTML (`<p>`, `<em>`, `<a href=...>`). Di sini tag
/// dibuang (paragraf dan `<br>` jadi baris baru, `<li>` jadi butir), lalu
/// entitas dasar seperti `&amp;` dan `&nbsp;` diterjemahkan.
///
/// Urutan sengaja: tag dibuang DULU baru entitas diterjemahkan, supaya
/// `&lt;b&gt;` di dalam teks tampil sebagai `<b>` dan tidak dianggap tag.
/// `&amp;` diterjemahkan paling akhir agar `&amp;lt;` tidak ikut terurai
/// dua kali.
String? estPlainText(Object? raw) {
  var text = '${raw ?? ''}';
  if (text.trim().isEmpty) return null;

  text = text
      .replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n')
      .replaceAll(RegExp(r'</(p|div|h[1-6]|li)>', caseSensitive: false), '\n')
      .replaceAll(RegExp(r'<li[^>]*>', caseSensitive: false), '• ')
      .replaceAll(RegExp(r'<[^>]*>'), '')
      .replaceAll('&nbsp;', ' ')
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>')
      .replaceAll('&quot;', '"')
      .replaceAllMapped(RegExp(r'&#(\d+);'), (m) {
        final code = int.tryParse(m[1]!);
        return code != null && code > 0 && code <= 0x10FFFF
            ? String.fromCharCode(code)
            : '';
      })
      .replaceAll('&amp;', '&');

  text = text
      .replaceAll(RegExp(r'[ \t]+\n'), '\n')
      .replaceAll(RegExp(r'\n{3,}'), '\n\n')
      .trim();

  return text.isEmpty ? null : text;
}
