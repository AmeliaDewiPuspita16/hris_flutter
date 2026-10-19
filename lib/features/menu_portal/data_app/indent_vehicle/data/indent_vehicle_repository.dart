import '../../../../../core/logging/app_logger.dart';
import '../../../../../core/network/api_client.dart';
import '../../../../../core/network/api_config.dart';
import '../../../../../core/network/api_exception.dart';
import '../../../../../core/network/page_meta.dart';
import '../domain/indent_driver.dart';
import '../domain/indent_request_item.dart';
import '../domain/indent_request_page.dart';

/// pintu ke API Indent Vehicle. Repository ini akan bertambah satu method
/// untuk tiap endpoint yang kita sambungkan.
class IndentVehicleRepository {
  IndentVehicleRepository({required ApiClient apiClient})
      : _apiClient = apiClient;

  final ApiClient _apiClient;

  /// id driver -> nama, diingat setelah berhasil dimuat supaya halaman 2,
  /// 3, dan seterusnya tidak mengambil ulang daftar driver yang sama.
  /// Diperbarui lagi setiap kali halaman 1 dimuat (muat awal / refresh).
  Map<int, String>? _driverNamesCache;

  Future<List<IndentDriver>> fetchDrivers() async {
    final raw = await _apiClient.getRawList(ApiConfig.indentDrivers);
    return [
      for (final item in raw)
        if (item is Map<String, dynamic>) IndentDriver.fromJson(item),
    ];
  }

  /// Satu halaman untuk tab "List of User Requests" — `GET /api/indent`,
  /// berisi request SEMUA user, urutan dari server (terbaru di atas).
  ///
  /// Bentuk respons: `{message, status, data: {current_page, last_page,
  /// ..., data: [ ...request... ]}}`. Objek `data` di tengah itulah yang
  /// dikembalikan `ApiClient.get`; daftarnya ada di `data['data']`, dan
  /// keterangan paginasinya ada di objek yang sama (dibaca [PageMeta]).
  ///
  /// [currentUserId] dipakai menandai mana request milik user yang sedang
  /// login (lihat [IndentRequestItem.isMine]).
  ///
  /// Nama driver tidak dikirim endpoint ini (cuma `id_driver`), jadi daftar
  /// driver diambil bersamaan lalu dicocokkan. Daftar driver itu pelengkap:
  /// bila gagal, daftar request tetap tampil (lihat [_driverNames]).
  ///
  /// Melempar [ApiException] bila daftar request-nya yang gagal.
  Future<IndentRequestPage> fetchRequests({
    int page = 1,
    int? currentUserId,
  }) async {
    // Dua-duanya dimulai dulu baru ditunggu, supaya berjalan paralel.
    final driverNamesRequest = _driverNames(refresh: page == 1);
    final data = await _apiClient.get(
      Uri(path: ApiConfig.indent, queryParameters: {'page': '$page'})
          .toString(),
    );
    final driverNames = await driverNamesRequest;

    final rows = data['data'];
    if (rows is! List) {
      throw const ApiException.server(
        'Daftar indent diterima, tapi bentuknya tidak dikenali.',
      );
    }

    final items = <IndentRequestItem>[];
    for (final row in rows.whereType<Map<String, dynamic>>()) {
      try {
        items.add(
          IndentRequestItem.fromJson(
            row,
            currentUserId: currentUserId,
            driverNames: driverNames,
          ),
        );
      } on FormatException catch (e) {
        // Satu baris cacat tidak boleh menghilangkan seluruh halaman.
        AppLogger.info('Melewati indent yang tidak bisa dibaca: $e');
      }
    }

    return IndentRequestPage(items: items, meta: PageMeta.fromJson(data));
  }

  /// id driver -> nama; kosong bila gagal. Tidak pernah melempar, karena
  /// kegagalan daftar driver tidak boleh membuat seluruh list request gagal.
  /// Hasil kosong akibat gagal tidak disimpan, jadi dicoba lagi lain kali.
  Future<Map<int, String>> _driverNames({required bool refresh}) async {
    final cached = _driverNamesCache;
    if (!refresh && cached != null) return cached;

    try {
      final drivers = await fetchDrivers();
      return _driverNamesCache = {for (final d in drivers) d.id: d.name};
    } on ApiException catch (e) {
      AppLogger.info('Daftar driver tidak dimuat untuk list indent: ${e.message}');
    } catch (e, stack) {
      AppLogger.error('Daftar driver gagal dimuat untuk list indent', e, stack);
    }
    return cached ?? const <int, String>{};
  }
}
