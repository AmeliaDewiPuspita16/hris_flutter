import '../../../../../../core/network/api_client.dart';
import '../../../../../../core/network/api_config.dart';
import '../../../../../../core/network/api_exception.dart';
import '../domain/it_request_detail.dart';
import '../domain/it_request_page.dart';

/// Riwayat IT/Media Request milik user sendiri. Tidak tahu soal HTTP — itu
/// urusan [ApiClient].
class ItRequestRepository {
  ItRequestRepository({required ApiClient apiClient}) : _apiClient = apiClient;

  final ApiClient _apiClient;

  /// Satu halaman riwayat request, beserta jumlah yang menunggu rating dan
  /// paginasinya.
  ///
  /// Melempar [ApiException] bila gagal.
  Future<ItRequestPage> fetchList({int page = 1, int perPage = 20}) async {
    final envelope = await _apiClient.getEnvelope(
      _pathWithQuery(ApiConfig.itRequest, {'page': '$page', 'per_page': '$perPage'}),
    );

    return ItRequestPage.fromEnvelope(envelope);
  }

  /// Rincian satu request.
  ///
  /// Melempar [ApiException] bila gagal, termasuk saat responsnya sampai
  /// tapi bentuknya tidak dikenali — layar detail cukup menangani satu
  /// jenis kegagalan, bukan juga [FormatException].
  Future<ItRequestDetail> fetchDetail(int id) async {
    final data = await _apiClient.get('${ApiConfig.itRequest}/$id');

    try {
      return ItRequestDetail.fromJson(data);
    } on FormatException {
      throw const ApiException.server(
        'Detail request diterima, tapi isinya tidak dikenali.',
      );
    }
  }

  static String _pathWithQuery(String path, Map<String, String> query) =>
      Uri(path: path, queryParameters: query).toString();
}
