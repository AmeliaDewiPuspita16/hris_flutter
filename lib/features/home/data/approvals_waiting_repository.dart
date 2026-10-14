import '../../../core/network/api_client.dart';
import '../../../core/network/api_config.dart';
import '../domain/approvals_waiting_summary.dart';

/// Ringkasan approval menunggu lintas modul (IT, EST Work Order, Indent
/// Vehicle, eProcurement) untuk banner "Approvals waiting" di Beranda.
/// Tidak tahu soal HTTP — itu urusan [ApiClient].
class ApprovalsWaitingRepository {
  ApprovalsWaitingRepository({required ApiClient apiClient})
      : _apiClient = apiClient;

  final ApiClient _apiClient;

  /// Melempar [ApiException] bila gagal.
  Future<ApprovalsWaitingSummary> fetchSummary() async {
    final data = await _apiClient.get(ApiConfig.approvalsWaiting);
    return ApprovalsWaitingSummary.fromJson(data);
  }
}
