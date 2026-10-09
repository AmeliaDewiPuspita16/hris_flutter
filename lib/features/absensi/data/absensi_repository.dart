import '../../../core/network/api_client.dart';
import '../../../core/network/api_config.dart';
import '../../../core/network/api_exception.dart';
import '../../home/domain/attendance_status.dart';
import '../domain/attendance_month.dart';

/// Sumber data absensi dari HRIS. Tidak tahu soal HTTP; itu urusan
/// [ApiClient].
///
/// Absensi READ ONLY: realisasi kehadiran berasal dari mesin fingerprint
/// kantor yang tersinkron ke HRIS, tidak ada check-in/out dari aplikasi.
class AbsensiRepository {
  AbsensiRepository({required ApiClient apiClient}) : _apiClient = apiClient;

  final ApiClient _apiClient;

  // static const _shiftTimeRanges = {
  //   'A': '08:00–16:00',
  //   'B': '16:00–00:00',
  //   'C': '00:00–08:00',
  // };

  /// jadwal & absensi hari ini, untuk kartu jam kerja di Beranda
  ///
  /// melempar [ApiException] bila gagal.
  Future<AttendanceStatus> fetchToday() async {
    final data = await _apiClient.get(ApiConfig.attendance);

    final schedule = data['today_schedule'];
    if (schedule is! Map<String, dynamic>) {
      throw const ApiException.server(
          'Jadwal hari ini tidak ditemukan pada respons server.');
    }

    return AttendanceStatus.fromJson(schedule);
  }

  /// Realisasi + ringkasan untuk seluruh tanggal di [month], dalam satu
  /// panggilan (selalu ditampilkan bersamaan di kalender).
  ///
  /// Melempar [ApiException] bila gagal.
  Future<AttendanceMonth> fetchMonth(DateTime month) async {
    final key = '${month.year}-${month.month.toString().padLeft(2, '0')}';
    final data = await _apiClient.get('${ApiConfig.attendance}?month=$key');

    return AttendanceMonth.fromJson(data, month: month);
  }
}
