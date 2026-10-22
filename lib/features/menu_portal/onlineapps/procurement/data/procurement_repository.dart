import '../../../../../core/logging/app_logger.dart';
import '../../../../../core/network/api_client.dart';
import '../../../../../core/network/api_config.dart';
import '../../../../../core/network/api_exception.dart';
import '../domain/pr_action.dart';
import '../domain/purchase_requisition.dart';
import '../domain/purchase_requisition_page.dart';

/// Procurement Monitoring. Tidak tahu soal HTTP — itu urusan [ApiClient].
class ProcurementRepository {
  ProcurementRepository({required ApiClient apiClient})
      : _apiClient = apiClient;

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

  /// Mode uji: aksi approve/revisi/reject TIDAK dikirim ke server, hanya
  /// dicatat di log. Aman dipakai di data sungguhan.
  ///
  /// ```
  /// flutter run --dart-define=PR_ACTION_DRY_RUN=true
  /// ```
  static const bool _dryRun = bool.fromEnvironment('PR_ACTION_DRY_RUN');

  /// Mengirim keputusan atas satu PR:
  /// `POST /api/portal/apps/eprocurement/{id}/{approve|revision|reject}`.
  ///
  /// [comments] wajib untuk revisi dan reject, opsional untuk approve. Yang
  /// kosong tidak dikirim. Isi respons tidak dipakai; pemanggil mengambil
  /// ulang detail PR untuk melihat keadaan terbarunya.
  ///
  /// Request ini tidak idempoten, jadi tidak pernah diulang otomatis.
  ///
  /// Melempar [ApiException] bila gagal.
  Future<void> submitAction(
    int id,
    PrAction action, {
    String? comments,
  }) async {
    final text = comments?.trim() ?? '';
    final path = ApiConfig.eprocurementAction(id, action.path);
    final body = <String, dynamic>{if (text.isNotEmpty) 'comments': text};

    if (_dryRun) {
      AppLogger.info('[DRY RUN] POST $path body=$body (tidak dikirim)');
      await Future<void>.delayed(const Duration(milliseconds: 800));
      return;
    }

    await _apiClient.postAction(path, body: body);
  }

  /// Menyusun path beserta query string yang sudah di-encode.
  ///
  /// [ApiClient] menerima path sebagai String, jadi encoding-nya dikerjakan
  /// di sini — kata kunci pencarian bisa memuat spasi, `&`, atau `/`.
  static String _pathWithQuery(String path, Map<String, String> query) =>
      Uri(path: path, queryParameters: query).toString();
}
