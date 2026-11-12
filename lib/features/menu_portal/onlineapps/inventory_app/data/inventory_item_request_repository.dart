import '../../../../../core/network/api_client.dart';
import '../../../../../core/network/api_config.dart';
import '../domain/item_request_options.dart';
import '../domain/stationery_request_page.dart';

/// Akses API Inventory > Item Request. Tidak tahu soal HTTP — itu urusan
/// [ApiClient]. Pola sama dengan `EstRequestRepository`.
///
/// Sudah tersambung: [fetchOptions], [fetchPendingCount], [fetchRequests].
/// Berikutnya: detail, submit, edit/cancel, verifikasi, approve/reject.
class InventoryItemRequestRepository {
  InventoryItemRequestRepository({required ApiClient apiClient})
      : _apiClient = apiClient;

  final ApiClient _apiClient;

  /// Bahan form + hak akses user — `GET /item-request/options`.
  ///
  /// [search] menyaring barang menurut kode atau nama di server. Kosong
  /// berarti semua barang aktif.
  ///
  /// Melempar `ApiException` bila gagal (mis. 403 untuk Daily Worker).
  Future<ItemRequestOptions> fetchOptions({String? search}) async {
    final query = search?.trim() ?? '';
    final path = query.isEmpty
        ? ApiConfig.itemRequestOptions
        : Uri(
            path: ApiConfig.itemRequestOptions,
            queryParameters: {'search': query},
          ).toString();

    final data = await _apiClient.get(path);
    return ItemRequestOptions.fromJson(data);
  }

  /// Angka badge — `GET /item-request/pending-count` -> `data.count`.
  ///
  /// Untuk Inventory Admin / Reviewer / Admin: line pending yang menunggu
  /// verifikasi (pada kategori yang boleh dikelola). Untuk akun lain: line
  /// pending miliknya sendiri.
  ///
  /// Melempar `ApiException` bila gagal.
  Future<int> fetchPendingCount() async {
    final data = await _apiClient.get(ApiConfig.itemRequestPendingCount);
    final count = data['count'];
    return count is num ? count.toInt() : 0;
  }

  /// Daftar LINE yang boleh dilihat user, request terbaru di atas -
  /// `GET /item-request`.
  ///
  /// Isinya milik sendirim ditambah (Inventory Admin / Reviewer / Admin)
  /// line orang lain pada kategori yang boleh dikelolanya. Semua penyaringan
  /// dilakukan server: [status] (`pending` | `approved` | `rejected`),
  /// [search] (kode request, kode/nama barang, nama requester), dan [mine]
  /// (hanya milik sendiri). Server tidak mengirim `summary`, hanya `meta`.
  ///
  /// Melempar `ApiException` bila gagal.
  Future<StationeryRequestPage> fetchRequests({
    int page = 1,
    int perPage = 20,
    String? status,
    String? search,
    bool mine = false,
  }) async {
    final keyword = search?.trim() ?? '';
    final path = Uri(
      path: ApiConfig.itemRequest,
      queryParameters: {
        'page': '$page',
        'per_page': '$perPage',
        if (status != null && status.isNotEmpty) 'status': status,
        if (keyword.isNotEmpty) 'search': keyword,
        if (mine) 'mine': '1',
      },
    ).toString();

    final envelope = await _apiClient.getEnvelope(path);
    return StationeryRequestPage.fromEnvelope(envelope);
  }
}
