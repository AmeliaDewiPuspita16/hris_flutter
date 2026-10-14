import '../../../core/network/api_client.dart';
import '../../../core/network/api_config.dart';
import '../domain/overtime_month.dart';

/// Sumber data lembur dari HRIS. Tidak tahu soal HTTP; itu urusan
/// [ApiClient].
///
/// Yang sudah tersambung: [fetchMonth] (realisasi lembur, tab Summary).
/// Pengajuan lembur (tab Submit dan Status) belum punya endpoint, jadi
/// masih lokal di layar.
class OvertimeRepository {
  OvertimeRepository({required ApiClient apiClient}) : _apiClient = apiClient;

  final ApiClient _apiClient;

  /// Realisasi lembur untuk satu bulan.
  ///
  /// Melempar [ApiException] bila gagal.
  Future<OvertimeMonth> fetchMonth(DateTime month) async {
    final key = '${month.year}-${month.month.toString().padLeft(2, '0')}';
    final data = await _apiClient.get('${ApiConfig.overtime}?month=$key');

    return OvertimeMonth.fromJson(data);
  }
}
