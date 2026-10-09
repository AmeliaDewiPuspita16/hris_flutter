import '../../../core/utils/json_value.dart';

/// Status kehadiran/jadwal untuk satu tanggal di kalender Log Absensi.
enum AttendanceDayStatus {
  tepatWaktu,
  terlambat,
  lembur,
  liburHari,
  berlangsung,

  /// Tanggal yang belum dijalani (biasanya di masa depan), tapi shift-nya
  /// sudah diinput HR di awal bulan. Belum ada realisasi jam masuk-pulang.
  terjadwal,
}

/// Satu tanggal di kalender Log Absensi.
///
/// Menggabungkan dua hal yang sifatnya beda:
/// - Jadwal shift ([shiftCode] & [shiftTimeRange]) — sudah diketahui di
///   awal bulan lewat input HR, berlaku untuk seluruh tanggal termasuk yang
///   belum terjadi.
/// - Realisasi kehadiran ([status], [timeText], [badgeLabel]) — baru ada
///   setelah tanggal itu berlalu/berlangsung, disinkron dari mesin
///   fingerprint via HRIS.
class AttendanceDay {
  const AttendanceDay({
    required this.date,
    required this.status,
    this.shiftCode,
    this.shiftTimeRange,
    this.timeText,
    this.noteText,
    this.badgeLabel,
  });

  /// satu entri 'days[]' dari 'GET / /api/portal/apps/hris/attendance?month=`.
  /// Null bila tanggalnya tidak terbaca.
  ///
  /// server hanay mengirim tanggal yang punya data kehadiran; tanggal lain
  /// diisi oleh [AttendanceMonth.fromJson].
  static AttendanceDay? tryFromJson(Map<String, dynamic> json) {
    final date = dateOrNull(json['date']);
    if (date == null) return null;

    final checkIn = dateOrNull(json['checkin'])?.toLocal();
    final checkOut = dateOrNull(json['checkout'])?.toLocal();
    final ongoing = checkIn != null && checkOut == null && _isToday(date);

    final status = _statusFrom(
      textOrNull(json['status']),
      hasCheckIn: checkIn != null,
      ongoing: ongoing,
    );

    return AttendanceDay(
      date: DateTime(date.year, date.month, date.day),
      status: status,
      // `shift` sejauh ini selalu null di respons; bentuk isinya belum
      // diketahui. Dibaca sebagai teks bila suatu saat terisi string.
      shiftCode: textOrNull(json['shift']),
      timeText: _timeText(checkIn, checkOut, ongoing: ongoing),
      badgeLabel: switch (status) {
        AttendanceDayStatus.tepatWaktu => 'Tepat waktu',
        AttendanceDayStatus.terlambat => 'Terlambat',
        AttendanceDayStatus.lembur => 'Lembur',
        _ => null,
      },
    );
  }

  /// Hanya "present" yang pernah terlihat di respons. "late", "overtime",
  /// "holiday", dan "off" adalah DUGAAN nama status; sesuaikan begitu
  /// backend memastikan daftar statusnya. Status yang tidak dikenal dianggap
  /// hadir kalau ada jam masuk, selain itu dianggap belum ada data.
  static AttendanceDayStatus _statusFrom(
    String? raw, {
    required bool hasCheckIn,
    required bool ongoing,
  }) {
    if (ongoing) return AttendanceDayStatus.berlangsung;

    switch (raw?.toLowerCase()) {
      case 'present':
        return AttendanceDayStatus.tepatWaktu;
      case 'late':
        return AttendanceDayStatus.terlambat;
      case 'overtime':
        return AttendanceDayStatus.lembur;
      case 'holiday':
      case 'off':
        return AttendanceDayStatus.liburHari;
    }
    return hasCheckIn
        ? AttendanceDayStatus.tepatWaktu
        : AttendanceDayStatus.terjadwal;
  }

  static String? _timeText(
    DateTime? checkIn,
    DateTime? checkOut, {
    required bool ongoing,
  }) {
    if (checkIn == null) return null;
    if (checkOut != null) return '${_hhmm(checkIn)} – ${_hhmm(checkOut)}';
    return ongoing
        ? '${_hhmm(checkIn)} — Berlangsung'
        : '${_hhmm(checkIn)} – belum ada data pulang';
  }

  static bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month && date.day == now.day;
  }

  static String _hhmm(DateTime t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';



  /// Tanggal kalender (bagian jam diabaikan).
  final DateTime date;

  final AttendanceDayStatus status;

  /// Kode shift terjadwal, mis. "A", "B", "C". Null untuk hari libur atau
  /// tanggal yang belum ada jadwalnya.
  final String? shiftCode;

  /// Rentang jam shift, mis. "07:00–16:00". Null bila [shiftCode] null.
  final String? shiftTimeRange;

  /// Jam masuk–pulang hasil realisasi, mis. "06:55 – 16:00". Hanya terisi
  /// untuk tanggal yang sudah berlalu atau sedang berlangsung.
  final String? timeText;

  /// Catatan tambahan, mis. "Lembur · Disetujui". Opsional.
  final String? noteText;

  /// Label badge kecil di panel detail, mis. "Telat 14m". Null bila hari
  /// itu belum punya hasil final (terjadwal/berlangsung) atau tidak relevan
  /// (hari libur).
  final String? badgeLabel;

  bool get isScheduledOnly => status == AttendanceDayStatus.terjadwal;

  bool isSameDay(DateTime other) =>
      date.year == other.year && date.month == other.month && date.day == other.day;
}
