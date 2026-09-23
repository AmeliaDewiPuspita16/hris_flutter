/// Status kehadiran per hari. Sumber datanya tetap dari mesin fingerprint
/// di kantor (sinkron ke sistem HRIS web) — aplikasi ini HANYA menampilkan,
/// tidak ada aksi absen dari mobile.
enum AttendanceStatus {
  tepatWaktu,
  terlambat,
  lembur,
  liburHari,
  berlangsung,
}

class AttendanceEntry {
  const AttendanceEntry({
    required this.day,
    required this.weekday,
    required this.primaryText,
    required this.secondaryText,
    required this.status,
  });

  /// Tanggal 2 digit, mis. "08".
  final String day;

  /// Singkatan hari 3 huruf, mis. "SEN".
  final String weekday;

  /// Baris utama: rentang jam kerja atau keterangan ("Hari libur", dst).
  final String primaryText;

  /// Baris kedua: info shift/jadwal atau catatan tambahan.
  final String secondaryText;

  final AttendanceStatus status;
}
