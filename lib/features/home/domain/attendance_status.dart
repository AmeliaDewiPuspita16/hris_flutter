import '../../../core/utils/json_value.dart';

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
  /// lokasi belum ada di API, jadi sementara tetap sttais seperti
  /// sebelumnya. Ganti kalau backend sudah menyediakannya.
  static const defaultLocation = 'Plant 2 · Gate A';

  /// membaca objek 'today_schedule' dari 'GET /api/portal/apps/hris/
  /// attendance'.
  ///
  /// Catt:
  /// - `started` sengaja belum dipakai.
  /// - `checked_in_at` / `checked_out_at` saat ini selalu null karena datanya
  ///   belum tersedia di server, bukan karena karyawannya belum absen. Selama
  ///   itu kartu selalu menampilkan "You have not clocked in yet". Format
  ///   isinya belum pernah terlihat, jadi nilai yang tidak bisa dibaca
  ///   dianggap null.
  factory AttendanceStatus.fromJson(Map<String, dynamic> json) {
    final checkedIn = dateOrNull(json['checked_in_at'])?.toLocal();
    final checkOut = dateOrNull(json['checked_out_at'])?.toLocal();

    return AttendanceStatus(
      shiftLabel: textOrNull(json['shift_label']) ?? '-',
      shiftTime: textOrNull(json['time_range']) ?? '-',
      location: defaultLocation,
      clockInTime: checkedIn == null ? null : _hhmm(checkedIn),
      workedDuration: checkedIn == null
          ? null
          : _worked(checkOut ?? DateTime.now(), since: checkedIn),
    );
  }

  static String _hhmm(DateTime t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  static String _worked(DateTime until, {required DateTime since}) {
    final d = until.difference(since);
    final minutes = d.isNegative ? 0 : d.inMinutes;
    final h = minutes ~/ 60;
    final m = (minutes % 60).toString().padLeft(2, '0');
    return '${h}h ${m}m worked';
  }
}
