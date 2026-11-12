import '../../../../../core/network/api_client.dart';
import '../../../../../core/network/api_config.dart';
import '../domain/item_request_options.dart';
import '../domain/item_request_detail.dart';
import '../domain/item_request_entry.dart';
import '../domain/item_request_page.dart';

/// Akses API Inventory > Item Request. Tidak tahu soal HTTP — itu urusan
/// [ApiClient]. Pola sama dengan `EstRequestRepository`.
///
/// Dibangun bertahap menggantikan `InventoryItemRequestDemoRepository` (data demo).
/// Sudah ada: [fetchOptions], [fetchPendingCount], [fetchRequests],
/// [fetchLine], [fetchRequest].
/// Berikutnya: submit, edit/cancel, verifikasi, approve/reject.
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

  /// Daftar LINE yang boleh dilihat user, request terbaru di atas —
  /// `GET /item-request`.
  ///
  /// Isinya milik sendiri, ditambah (Inventory Admin / Reviewer / Admin)
  /// line orang lain pada kategori yang boleh dikelolanya. Semua penyaringan
  /// dilakukan server: [status] (`pending` | `approved` | `rejected`),
  /// [search] (kode request, kode/nama barang, nama requester), dan [mine]
  /// (hanya milik sendiri). Server tidak mengirim `summary`, hanya `meta`.
  ///
  /// Melempar `ApiException` bila gagal.
  Future<ItemRequestPage> fetchRequests({
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
    return ItemRequestPage.fromEnvelope(envelope);
  }

  /// Satu LINE berikut request induknya — `GET /item-request/{line_id}`.
  /// Bedanya dengan baris di daftar: memuat `current_stock` (total stok
  /// barang saat ini), jadi dipakai sheet detail untuk "Current stock".
  ///
  /// Melempar `ApiException` bila gagal (403 / 404).
  Future<ItemRequestEntry> fetchLine(int lineId) async {
    final data = await _apiClient.get(ApiConfig.itemRequestLine(lineId));
    return ItemRequestEntry.fromJson(data);
  }

  /// Satu REQUEST dengan semua line yang boleh dilihat user —
  /// `GET /item-request/requests/{request_id}`.
  ///
  /// Melempar `ApiException` bila gagal: 403 bila user tidak boleh melihat
  /// satu pun line-nya, 404 bila request tidak ada.
  Future<ItemRequestDetail> fetchRequest(int requestId) async {
    final data = await _apiClient.get(ApiConfig.itemRequestDetail(requestId));
    return ItemRequestDetail.fromJson(data);
  }
}
