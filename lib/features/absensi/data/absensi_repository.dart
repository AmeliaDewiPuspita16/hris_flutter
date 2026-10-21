import '../../../core/logging/app_logger.dart';
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
          'Today\'s schedule was not found in the server response.');
    }

    return AttendanceStatus.fromJson(schedule);
  }

  /// Realisasi + ringkasan untuk seluruh tanggal di [month], dalam satu
  /// panggilan (selalu ditampilkan bersamaan di kalender).
  ///
  /// Data lembur diambil dari endpoint terpisah dan dimuat bersamaan. Itu
  /// pelengkap: bila gagal, absensi tetap tampil (lihat [_fetchOvertime]).
  ///
  /// Melempar [ApiException] bila data absensinya yang gagal.
  Future<AttendanceMonth> fetchMonth(DateTime month) async {
    final key = '${month.year}-${month.month.toString().padLeft(2, '0')}';

    // Keduanya dimulai dulu baru ditunggu, supaya berjalan paralel.
    final attendanceRequest = _apiClient.get('${ApiConfig.attendance}?month=$key');
    final overtimeRequest = _fetchOvertime(key);

    final data = await attendanceRequest;
    final overtime = await overtimeRequest;

    return AttendanceMonth.fromJson(data, month: month, overtime: overtime);
  }

  /// Lembur sebulan; null bila gagal. Tidak pernah melempar, karena
  /// kegagalan lembur tidak boleh membuat seluruh Log Absensi gagal.
  Future<Map<String, dynamic>?> _fetchOvertime(String monthKey) async {
    try {
      return await _apiClient.get('${ApiConfig.overtime}?month=$monthKey');
    } on ApiException catch (e) {
      AppLogger.info('Data lembur $monthKey tidak dimuat: ${e.message}');
    } catch (e, stack) {
      AppLogger.error('Data lembur $monthKey gagal dimuat', e, stack);
    }
    return null;
  }
}
