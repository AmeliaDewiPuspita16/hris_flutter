/// Ringkasan absensi hari ini yang tampil tepat di bawah header Beranda.
class AttendanceStatus {
  const AttendanceStatus({
    required this.shiftLabel,
    required this.shiftTime,
    required this.location,
    this.clockInTime,
    this.workedDuration,
  });

  /// Nama jadwal kerja, mis. "Office Hours".
  final String shiftLabel;

  /// Rentang jam kerja, mis. "08:00–17:00".
  final String shiftTime;

  /// Titik absen, mis. "Plant 2 · Gate A".
  final String location;

  /// Jam masuk. Null kalau belum absen masuk hari ini.
  final String? clockInTime;

  /// Lama bekerja sejauh ini, mis. "6h 08m worked".
  final String? workedDuration;

  bool get isClockedIn => clockInTime != null;

  /// Kalimat status di baris bawah kartu.
  String get statusText => isClockedIn
      ? 'Clocked in $clockInTime · $workedDuration'
      : 'You have not clocked in yet';

  /// Label tombol — menyesuaikan apakah sudah absen masuk atau belum.
  String get actionLabel => isClockedIn ? 'Clock out' : 'Clock in';
}
