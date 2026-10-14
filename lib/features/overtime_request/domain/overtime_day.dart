import '../../../core/utils/json_value.dart';

/// Lembur yang sudah TERJADI pada satu hari — realisasi dari check-in/out
/// fingerprint, bukan pengajuan. Satu item `days[]` dari
/// `GET /api/portal/apps/hris/overtime`.
class OvertimeDay {
  const OvertimeDay({
    required this.date,
    required this.minutes,
    this.checkIn,
    this.checkOut,
    this.shift,
  });

  /// Satu item `days[]`:
  /// ```json
  /// { "date": "2026-10-03", "overtime_minutes": 90, "overtime_hours": 1.5,
  ///   "checkin": "2026-10-03T07:52:00+07:00",
  ///   "checkout": "2026-10-03T18:30:00+07:00",
  ///   "shift": "N (08:00-17:00) - Normal Shift" }
  /// ```
  /// Null bila tanggalnya tidak terbaca.
  static OvertimeDay? tryFromJson(Map<String, dynamic> json) {
    final date = dateOrNull(json['date']);
    if (date == null) return null;

    // `overtime_minutes` yang utama; `overtime_hours` hanya cadangan.
    final minutes = json['overtime_minutes'] != null
        ? amountOrZero(json['overtime_minutes'])
        : (doubleOrZero(json['overtime_hours']) * 60).round();

    return OvertimeDay(
      date: DateTime(date.year, date.month, date.day),
      minutes: minutes,
      checkIn: dateOrNull(json['checkin'])?.toLocal(),
      checkOut: dateOrNull(json['checkout'])?.toLocal(),
      shift: _shiftText(textOrNull(json['shift'])),
    );
  }

  /// "N (08:00-17:00) - Normal Shift" → "N (08:00–17:00)". Teks dengan pola
  /// lain dipakai apa adanya.
  static String? _shiftText(String? raw) {
    if (raw == null) return null;

    final match = RegExp(r'^\s*(\S+?)\s*\((.+?)\)').firstMatch(raw);
    if (match == null) return raw.trim();

    return '${match.group(1)} (${match.group(2)!.replaceAll('-', '–')})';
  }

  final DateTime date;

  /// Lama lembur dalam menit (`overtime_minutes`).
  final int minutes;

  final DateTime? checkIn;
  final DateTime? checkOut;

  /// Mis. "N (08:00–17:00)". Null bila server tidak mengirim shift.
  final String? shift;
}
