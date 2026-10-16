import '../../../../../core/logging/app_logger.dart';
import '../../../../../core/network/api_client.dart';
import '../../../../../core/network/api_config.dart';
import '../../../../../core/network/api_exception.dart';
import '../domain/indent_driver.dart';
import '../domain/indent_request_item.dart';

/// pintu ke API Indent Vehicle. Repository ini akan bertambah satu method
/// untuk tiap endpoint yang kita sambungkan.
class IndentVehicleRepository {
  IndentVehicleRepository({required ApiClient apiClient})
      : _apiClient = apiClient;

  final ApiClient _apiClient;

  Future<List<IndentDriver>> fetchDrivers() async {
    final raw = await _apiClient.getRawList(ApiConfig.indentDrivers);
    return [
      for (final item in raw)
        if (item is Map<String, dynamic>) IndentDriver.fromJson(item),
    ];
  }

  /// Daftar request untuk tab "List of User Requests" — `GET /api/indent`,
  /// berisi request SEMUA user, terbaru di atas.
  ///
  /// [currentUserId] / [currentUserName] dipakai menandai mana request
  /// milik user yang sedang login (lihat [IndentRequestItem.isMine]).
  ///
  /// Nama driver tidak dikirim endpoint ini (cuma `id_driver`), jadi
  /// daftar driver diambil bersamaan lalu dicocokkan. Daftar driver itu
  /// pelengkap: bila gagal, daftar request tetap tampil (lihat
  /// [_driverNamesOrEmpty]).
  ///
  /// Melempar [ApiException] bila daftar request-nya yang gagal.
  Future<List<IndentRequestItem>> fetchRequests({
    int? currentUserId,
    String? currentUserName,
  }) async {
    // Dua-duanya dimulai dulu baru ditunggu, supaya berjalan paralel.
    final driversRequest = _driverNamesOrEmpty();
    final rows = await _apiClient.getList(ApiConfig.indent);
    final driverNames = await driversRequest;

    final items = <IndentRequestItem>[];
    for (final row in rows.whereType<Map<String, dynamic>>()) {
      try {
        items.add(
          IndentRequestItem.fromJson(
            row,
            currentUserId: currentUserId,
            currentUserName: currentUserName,
            driverNames: driverNames,
          ),
        );
      } on FormatException catch (e) {
        // Satu baris cacat tidak boleh menghilangkan seluruh daftar.
        AppLogger.info('Melewati indent yang tidak bisa dibaca: $e');
      }
    }

    // Server mengurutkan dari yang terlama; yang terbaru lebih berguna di
    // atas. id bertambah terus, jadi id terbesar = terbaru.
    items.sort(
      (a, b) => (int.tryParse(b.id) ?? 0).compareTo(int.tryParse(a.id) ?? 0),
    );
    return items;
  }

  /// id driver -> nama; kosong bila gagal. Tidak pernah melempar, karena
  /// kegagalan daftar driver tidak boleh membuat seluruh list request gagal.
  Future<Map<int, String>> _driverNamesOrEmpty() async {
    try {
      final drivers = await fetchDrivers();
      return {for (final d in drivers) d.id: d.name};
    } on ApiException catch (e) {
      AppLogger.info('Daftar driver tidak dimuat untuk list indent: ${e.message}');
    } catch (e, stack) {
      AppLogger.error('Daftar driver gagal dimuat untuk list indent', e, stack);
    }
    return const <int, String>{};
  }
}
