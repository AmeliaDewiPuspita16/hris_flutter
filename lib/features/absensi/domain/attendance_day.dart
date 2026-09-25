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
