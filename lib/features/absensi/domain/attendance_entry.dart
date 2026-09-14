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

  /// dummy 1 bulan (nanti diganti hasil sinkron dari sistem fingerprint/HRIS web).
  static const dummySeptember2026 = [
    AttendanceEntry(
      day: '08',
      weekday: 'SEN',
      primaryText: '06:52 — Berlangsung',
      secondaryText: 'Shift A · 07:00–16:00',
      status: AttendanceStatus.berlangsung,
    ),
    AttendanceEntry(
      day: '07',
      weekday: 'MIN',
      primaryText: 'Hari libur',
      secondaryText: '—',
      status: AttendanceStatus.liburHari,
    ),
    AttendanceEntry(
      day: '06',
      weekday: 'SAB',
      primaryText: '16:00 – 20:30',
      secondaryText: 'Lembur · Disetujui',
      status: AttendanceStatus.lembur,
    ),
    AttendanceEntry(
      day: '05',
      weekday: 'JUM',
      primaryText: '07:14 – 16:03',
      secondaryText: 'Shift A · 07:00–16:00',
      status: AttendanceStatus.terlambat,
    ),
    AttendanceEntry(
      day: '04',
      weekday: 'KAM',
      primaryText: '06:48 – 16:05',
      secondaryText: 'Shift A · 07:00–16:00',
      status: AttendanceStatus.tepatWaktu,
    ),
    AttendanceEntry(
      day: '03',
      weekday: 'RAB',
      primaryText: '06:55 – 16:00',
      secondaryText: 'Shift A · 07:00–16:00',
      status: AttendanceStatus.tepatWaktu,
    ),
  ];
}
