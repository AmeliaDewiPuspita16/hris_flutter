import '../../../../../../core/network/api_client.dart';
import '../../../../../../core/network/api_config.dart';
import '../domain/est_approval_page.dart';

/// Akses API EST Work Order. Tidak tahu soal HTTP — itu urusan
/// `ApiClient`. Saat ini baru antrean approval HOD; daftar All Request,
/// submit, dan lainnya menyusul.
class EstRequestRepository {
  EstRequestRepository({required ApiClient apiClient})
      : _apiClient = apiClient;

  final ApiClient _apiClient;

  /// Antrean HOD: request dari department-nya yang masih `status = 0`
  /// (menunggu HOD).
  ///
  /// Server memaginasi hasilnya (`meta.current_page/last_page/total`).
  /// Belum ada infinite scroll di tab Approve HOD, jadi [perPage] sengaja
  /// besar — antrean satu department jarang sebanyak itu, dan badge tetap
  /// akurat karena memakai `summary.pending`.
  ///
  /// [type] (`Repair` atau `Project`) menyaring di sisi server lewat
  /// `?type=`.
  ///
  /// Melempar `ApiException` bila gagal (mis. 403 untuk akun bukan HOD).
  Future<EstApprovalPage> fetchApprovals({
    int page = 1,
    int perPage = 100,
    String? type,
  }) async {
    final envelope = await _apiClient.getEnvelope(
      _pathWithQuery(ApiConfig.estRequestApprovals, {
        'page': '$page',
        'per_page': '$perPage',
        if (type != null) 'type': type,
      }),
    );

    return EstApprovalPage.fromEnvelope(envelope);
  }

  /// HOD menyetujui request: status di server jadi 1 dan `approval_hod`
  /// diisi id HOD yang sedang login (server yang mengisi, bukan aplikasi).
  ///
  /// Melempar `ApiException` bila gagal.
  Future<void> approve(int id) =>
      _apiClient.postAction(ApiConfig.estRequestApprove(id));

  /// HOD menolak request: status di server jadi 4. [reason] opsional
  /// (maks 1000 karakter); kosong berarti tidak dikirim sama sekali.
  ///
  /// Melempar `ApiException` bila gagal, termasuk galat validasi.
  Future<void> reject(int id, {String? reason}) => _apiClient.postAction(
        ApiConfig.estRequestReject(id),
        body: {
          if (reason != null && reason.trim().isNotEmpty)
            'reason': reason.trim(),
        },
      );

  static String _pathWithQuery(String path, Map<String, String> query) =>
      Uri(path: path, queryParameters: query).toString();
}
