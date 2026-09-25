import '../../../core/network/api_client.dart';
import '../domain/attendance_day.dart';
import '../domain/attendance_month.dart';
import '../domain/attendance_summary.dart';

/// Sumber data Log Absensi.
///
/// BELUM ada endpoint HRIS untuk modul ini — method di bawah mengembalikan
/// data dummy lewat `Future.delayed` supaya UI (loading state, ganti bulan,
/// pilih tanggal, dst) sudah bisa diuji sekarang. [ApiClient] sudah disuntik
/// lebih dulu supaya saat endpoint-nya siap, hanya isi method ini yang
/// perlu diganti jadi `_apiClient.get(...)` — tidak ada screen, bloc, atau
/// widget yang perlu ikut berubah.
///
/// Realisasi kehadiran berasal dari mesin fingerprint kantor yang
/// tersinkron ke HRIS web (read-only, tidak ada submit/check-in dari sini).
/// Jadwal shift per tanggal juga berasal dari HRIS — diinput HR di awal
/// bulan untuk seluruh tanggal, termasuk yang belum terjadi.
class AbsensiRepository {
  AbsensiRepository({required ApiClient apiClient}) : _apiClient = apiClient;

  // ignore: unused_field
  final ApiClient _apiClient;

  static const _simulatedLatency = Duration(milliseconds: 500);

  static const _shiftTimeRanges = {
    'A': '08:00–16:00',
    'B': '16:00–00:00',
    'C': '00:00–08:00',
  };

  /// Jadwal + realisasi untuk seluruh tanggal di [month], dalam satu
  /// panggilan (selalu ditampilkan bersamaan di kalender, jadi lebih pas
  /// diambil sekaligus).
  Future<AttendanceMonth> fetchMonth(DateTime month) async {
    await Future.delayed(_simulatedLatency);

    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final days = [
      for (var d = 1; d <= daysInMonth; d++)
        _dummyDay(DateTime(month.year, month.month, d)),
    ];

    // dummy: ringkasan sama untuk bulan mana pun sampai endpoint HRIS-nya
    // tersedia.
    return AttendanceMonth(
      summary: const AttendanceSummary(present: 20, late: 1, overtimeHrs: 18),
      days: days,
    );
  }

  /// Tanggal 1–8 diisi data realisasi tetap (mengikuti contoh desain),
  /// sisanya jadi jadwal shift bergilir sebagai contoh. Ganti seluruhnya
  /// dengan hasil `_apiClient.get(...)` begitu endpoint HRIS tersedia.
  AttendanceDay _dummyDay(DateTime date) {
    switch (date.day) {
      case 1:
      case 2:
        return AttendanceDay(
          date: date,
          status: AttendanceDayStatus.tepatWaktu,
          shiftCode: 'A',
          shiftTimeRange: _shiftTimeRanges['A'],
        );
      case 3:
        return AttendanceDay(
          date: date,
          status: AttendanceDayStatus.tepatWaktu,
          shiftCode: 'A',
          shiftTimeRange: _shiftTimeRanges['A'],
          timeText: '06:55 – 16:00',
          badgeLabel: 'Tepat waktu',
        );
      case 4:
        return AttendanceDay(
          date: date,
          status: AttendanceDayStatus.tepatWaktu,
          shiftCode: 'B',
          shiftTimeRange: _shiftTimeRanges['B'],
          timeText: '14:02 – 22:10',
          badgeLabel: 'Tepat waktu',
        );
      case 5:
        return AttendanceDay(
          date: date,
          status: AttendanceDayStatus.terlambat,
          shiftCode: 'A',
          shiftTimeRange: _shiftTimeRanges['A'],
          timeText: '07:14 – 16:03',
          badgeLabel: 'Telat 14m',
        );
      case 6:
        return AttendanceDay(
          date: date,
          status: AttendanceDayStatus.lembur,
          shiftCode: 'C',
          shiftTimeRange: _shiftTimeRanges['C'],
          timeText: '22:00 – 02:30',
          noteText: 'Lembur · Disetujui',
          badgeLabel: 'Lbr 4,5j',
        );
      case 7:
        return AttendanceDay(
          date: date,
          status: AttendanceDayStatus.liburHari,
          noteText: 'Hari libur',
        );
      case 8:
        return AttendanceDay(
          date: date,
          status: AttendanceDayStatus.berlangsung,
          shiftCode: 'A',
          shiftTimeRange: _shiftTimeRanges['A'],
          timeText: '06:52 — Berlangsung',
        );
      default:
        // Sabtu & Minggu dianggap hari libur terjadwal; hari kerja lain
        // dapat shift bergilir sebagai contoh.
        final isWeekend =
            date.weekday == DateTime.saturday || date.weekday == DateTime.sunday;
        if (isWeekend) {
          return AttendanceDay(date: date, status: AttendanceDayStatus.terjadwal);
        }
        const rotation = ['A', 'A', 'B', 'B', 'C'];
        final code = rotation[date.day % rotation.length];
        return AttendanceDay(
          date: date,
          status: AttendanceDayStatus.terjadwal,
          shiftCode: code,
          shiftTimeRange: _shiftTimeRanges[code],
        );
    }
  }
}
