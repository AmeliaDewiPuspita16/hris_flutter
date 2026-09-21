import '../../../../../core/network/api_client.dart';
import '../../../../../core/network/api_config.dart';
import '../../../../../core/network/api_exception.dart';
import '../domain/purchase_requisition.dart';
import '../domain/purchase_requisition_page.dart';

/// Procurement Monitoring. Tidak tahu soal HTTP — itu urusan [ApiClient].
class ProcurementRepository {
  ProcurementRepository({required ApiClient apiClient}) : _apiClient = apiClient;

  final ApiClient _apiClient;

  /// Satu halaman daftar PR, beserta jumlah per status dan paginasinya.
  ///
  /// [statusCode] dan [search] yang kosong sengaja tidak dikirim: server
  /// memperlakukan `?status=` kosong berbeda dari parameter yang absen.
  ///
  /// Melempar [ApiException] bila gagal.
  Future<PurchaseRequisitionPage> fetchList({
    int page = 1,
    int perPage = 20,
    String? statusCode,
    String? search,
  }) async {
    final keyword = search?.trim() ?? '';

    final envelope = await _apiClient.getEnvelope(
      _pathWithQuery(ApiConfig.eprocurement, {
        'page': '$page',
        'per_page': '$perPage',
        if (statusCode != null && statusCode.isNotEmpty) 'status': statusCode,
        if (keyword.isNotEmpty) 'search': keyword,
      }),
    );

    return PurchaseRequisitionPage.fromEnvelope(envelope);
  }

  /// Rincian satu PR.
  ///
  /// Melempar [ApiException] bila gagal, termasuk saat responsnya sampai
  /// tapi bentuknya tidak dikenali — layar detail cukup menangani satu jenis
  /// kegagalan, bukan juga [FormatException].
  Future<PurchaseRequisition> fetchDetail(int id) async {
    final data = await _apiClient.get('${ApiConfig.eprocurement}/$id');

    try {
      return PurchaseRequisition.fromJson(data);
    } on FormatException {
      throw const ApiException.server(
        'Detail PR diterima, tapi isinya tidak dikenali.',
      );
    }
  }

  /// Menyusun path beserta query string yang sudah di-encode.
  ///
  /// [ApiClient] menerima path sebagai String, jadi encoding-nya dikerjakan
  /// di sini — kata kunci pencarian bisa memuat spasi, `&`, atau `/`.
  static String _pathWithQuery(String path, Map<String, String> query) =>
      Uri(path: path, queryParameters: query).toString();
}
