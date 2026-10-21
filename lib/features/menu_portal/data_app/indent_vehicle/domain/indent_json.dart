import '../../../../../core/utils/json_value.dart';

/// Pembaca field JSON Indent yang dipakai bersama oleh model-model Indent
/// (daftar request, approval HOD, dan nanti pending assignment), supaya
/// aturan membacanya hanya ada di satu tempat.

/// Server kadang mengirim angka sebagai teks; keduanya diterima. Null bila
/// bukan angka.
int? indentInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value);
  return null;
}

/// '2024-12-01' -> '01-12-2024' (format yang dipakai layar Indent). Kalau
/// bukan tanggal ISO, teks aslinya dipakai apa adanya.
String indentDate(dynamic value) {
  final date = dateOrNull(value);
  if (date == null) return textOrNull(value) ?? '-';

  String two(int n) => n.toString().padLeft(2, '0');
  return '${two(date.day)}-${two(date.month)}-${date.year}';
}

/// `jam_pergi` + `jam_pulang` -> '08:00:00 to 09:05:00'.
String indentTimeRange(Map<String, dynamic> json) {
  final from = textOrNull(json['jam_pergi']) ?? '--:--';
  final until = textOrNull(json['jam_pulang']) ?? '--:--';
  return '$from to $until';
}

/// Field `driver` di baris mentah berupa angka (1 = pakai driver, 0 =
/// tanpa driver). Nilai yang tidak dikenali dianggap pakai driver.
bool indentWithDriver(dynamic value) => switch (value) {
      bool() => value,
      num() => value != 0,
      String() =>
        value.isNotEmpty &&
            value != '0' &&
            value.toLowerCase() != 'tanpa driver',
      _ => true,
    };
