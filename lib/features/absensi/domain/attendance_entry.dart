/// Status kehadiran per hari. 

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

  /// Tanggal 2 digit, ex: "08".
  final String day;

  /// Singkatan hari 3 huruf, ex: "SEN".
  final String weekday;

  /// Baris utama: rentang jam kerja atau keterangan ("Hari libur", dst).
  final String primaryText;

  /// Baris kedua: info shift/jadwal atau catatan tambahan.
  final String secondaryText;

  final AttendanceStatus status;

  /// dummy 1 bulan 
  static const dummySeptember2026 = [
    AttendanceEntry(
      day: '08',
      weekday: 'MON',
      primaryText: '06:52 — In Progress',
      secondaryText: 'Shift A · 07:00–16:00',
      status: AttendanceStatus.berlangsung,
    ),
    AttendanceEntry(
      day: '07',
      weekday: 'SUN',
      primaryText: 'Rest day',
      secondaryText: '—',
      status: AttendanceStatus.liburHari,
    ),
    AttendanceEntry(
      day: '06',
      weekday: 'SAT',
      primaryText: '16:00 – 20:30',
      secondaryText: 'Overtime · Approved',
      status: AttendanceStatus.lembur,
    ),
    AttendanceEntry(
      day: '05',
      weekday: 'FRI',
      primaryText: '07:14 – 16:03',
      secondaryText: 'Shift A · 07:00–16:00',
      status: AttendanceStatus.terlambat,
    ),
    AttendanceEntry(
      day: '04',
      weekday: 'THU',
      primaryText: '06:48 – 16:05',
      secondaryText: 'Shift A · 07:00–16:00',
      status: AttendanceStatus.tepatWaktu,
    ),
    AttendanceEntry(
      day: '03',
      weekday: 'WED',
      primaryText: '06:55 – 16:00',
      secondaryText: 'Shift A · 07:00–16:00',
      status: AttendanceStatus.tepatWaktu,
    ),
  ];
}
