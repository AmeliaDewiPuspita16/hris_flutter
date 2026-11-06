import '../../../core/network/api_client.dart';
import '../../../core/network/api_config.dart';
import '../domain/overtime_month.dart';
import '../domain/overtime_request_entry.dart';
import '../domain/overtime_submission.dart';

/// Sumber data lembur dari HRIS. Tidak tahu soal HTTP; itu urusan
/// [ApiClient].
class OvertimeRepository {
  OvertimeRepository({required ApiClient apiClient}) : _apiClient = apiClient;

  final ApiClient _apiClient;

  /// Lembur yang disetujui untuk satu bulan.
  ///
  /// Melempar [ApiException] bila gagal.
  Future<OvertimeMonth> fetchMonth(DateTime month) async {
    final key = '${month.year}-${month.month.toString().padLeft(2, '0')}';
    final data = await _apiClient.get('${ApiConfig.overtime}?month=$key');

    return OvertimeMonth.fromJson(data);
  }

  /// Riwayat pengajuan lembur, urutan mengikuti server (tanggal terbaru dulu).
  ///
  /// Melempar [ApiException] bila gagal.
  Future<List<OvertimeRequestEntry>> fetchRequests() async {
    final rows = await _apiClient.getList(ApiConfig.overtimeRequest);

    return rows
        .whereType<Map<String, dynamic>>()
        .map(OvertimeRequestEntry.fromJson)
        .toList();
  }

  /// Mengajukan lembur baru.
  ///
  /// Melempar [ApiException] bila gagal; pesannya siap ditampilkan, termasuk
  /// penolakan server seperti pengajuan ganda.
  Future<OvertimeRequestEntry> submitRequest(OvertimeSubmission request) async {
    final data = await _apiClient.post(
      ApiConfig.overtimeRequest,
      body: request.toJson(),
    );

    return OvertimeRequestEntry.fromJson(data);
  }
}
