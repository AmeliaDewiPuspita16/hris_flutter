import '../../../core/network/api_client.dart';
import '../domain/attendance_entry.dart';
import '../domain/attendance_month.dart';
import '../domain/attendance_summary.dart';

/// Sumber data Log Absensi.
///
/// BELUM ada endpoint HRIS untuk modul ini — method di bawah mengembalikan
/// data dummy lewat `Future.delayed` supaya UI (loading state, ganti bulan,
/// dst) sudah bisa diuji sekarang. [ApiClient] sudah disuntik lebih dulu
/// supaya saat endpoint-nya siap, hanya isi method ini yang perlu diganti
/// jadi `_apiClient.get(...)` — tidak ada screen, bloc, atau widget yang perlu ikut berubah.
///
/// Data absensi sesungguhnya berasal dari mesin fingerprint kantor yang
/// tersinkron ke HRIS web, bukan diinput lewat aplikasi ini — jadi
/// repository ini juga TIDAK akan pernah punya method submit/check-in.
class AbsensiRepository {
  AbsensiRepository({required ApiClient apiClient}) : _apiClient = apiClient;

  // ignore: unused_field
  final ApiClient _apiClient;

  static const _simulatedLatency = Duration(milliseconds: 500);

  /// Entri harian + ringkasan untuk [month], dalam satu panggilan (selalu
  /// ditampilkan bersamaan, jadi lebih pas diambil sekaligus).
  Future<AttendanceMonth> fetchMonth(DateTime month) async {
    await Future.delayed(_simulatedLatency);

    // dummy: sama untuk bulan mana pun sampai endpoint HRIS-nya tersedia.
    return const AttendanceMonth(
      summary: AttendanceSummary(present: 20, late: 1, overtimeHrs: 18),
      entries: [
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
      ],
    );
  }
}
