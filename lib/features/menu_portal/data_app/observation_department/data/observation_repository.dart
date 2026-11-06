import 'package:hris_mobile/features/menu_portal/data_app/observation_department/domain/observation_options.dart';

import '../../../../../core/logging/app_logger.dart';
import '../../../../../core/network/api_client.dart';
import '../../../../../core/network/api_config.dart';
import '../../../../../core/network/api_exception.dart';
import '../domain/observation_category.dart';
import '../domain/observation_item.dart';

/// Pintu ke API Observation Department. Disambungkan bertahap, satu
/// endpoint per langkah:
///
/// - [fetchAll] — SUDAH dari API (`GET /api/data/observation`).
/// - [fetchOpenFromMyDept] - SUDAH juga (`GET /api/data/observation/requests`)
/// - [add], [update], [delete], [close] — BELUM
class ObservationRepository {
  ObservationRepository({required ApiClient apiClient})
      : _apiClient = apiClient;

  final ApiClient _apiClient;

  /// Jumlah baris per request dan batas pengaman jumlah halaman yang
  /// diambil, supaya loop tidak berputar tanpa akhir bila `meta` aneh.
  static const _perPage = 100;
  static const _maxPages = 50;

  static const _notConnected =
      'This feature is not connected to the server yet.';

  /// Pilihan form (kategori, sub-kategori, department, aturan foto) dari
  /// `GET /api/data/observation/options`. Dipanggil tiap form dibuka, tanpa
  /// cache, supaya perubahan di server langsung terbaca.
  Future<ObservationOptions> fetchOptions() async {
    final data = await _apiClient.get(ApiConfig.observationOptions);
    try {
      return ObservationOptions.fromJson(data);
    } on Object catch (e) {
      AppLogger.info('Options observation tidak terbaca: $e');
      throw const ApiException.server(
        'The form options were received, but their format was not recognized.'
      );
    }
  }

  /// Tabel "All Observations": semua observasi, terbaru di atas.
  ///
  /// Semua halaman diambil sekaligus (mengikuti `meta.last_page`) karena
  /// pencarian dan filter di layar masih dilakukan lokal atas seluruh data.
  /// Melempar [ApiException] bila request gagal.
  Future<List<ObservationItem>> fetchAll() =>
      _fetchAllPages(ApiConfig.observation);

  /// Tab "To Close": temuan berstatus open yang ditujukan ke department
  /// user atau dibuat oleh user sendiri. Hanya yang 'can_close = true' yang
  /// mendapat tombol close.
  Future<List<ObservationItem>> fetchOpenFromMyDept() =>
      _fetchAllPages(ApiConfig.observationRequests);

  /// Mengambil semua halaman dari [path] (mengikuti `meta.last_page`).
  Future<List<ObservationItem>> _fetchAllPages(String path) async {
    final items = <ObservationItem>[];
    var page = 1;
    var lastPage = 1;

    do {
      final envelope = await _apiClient.getEnvelope(
        Uri(
          path: path,
          queryParameters: {'per_page': '$_perPage', 'page': '$page'},
        ).toString(),
      );

      final rows = envelope['data'];
      if (rows is! List) {
        throw const ApiException.server(
          'The observation list was received, but its format was not recognized.',
        );
      }

      for (final row in rows.whereType<Map<String, dynamic>>()) {
        try {
          items.add(ObservationItem.fromJson(row));
        } on FormatException catch (e) {
          // Satu baris rusak tidak boleh menggagalkan seluruh daftar.
          AppLogger.info('Observation dilewati: ${e.message}');
        }
      }

      lastPage = _lastPage(envelope['meta']);
      page++;
    } while (page <= lastPage && page <= _maxPages);

    return _sorted(items);
  }

  /// `meta.last_page` bisa datang sebagai angka atau teks; 1 bila tak ada.
  int _lastPage(dynamic meta) {
    if (meta is! Map) return 1;
    final value = meta['last_page'];
    final parsed = value is num ? value.toInt() : int.tryParse('$value');
    return (parsed == null || parsed < 1) ? 1 : parsed;
  }

  List<ObservationItem> _sorted(Iterable<ObservationItem> items) {
    final list = items.toList()
      ..sort((a, b) {
        final byDate = b.createdDate.compareTo(a.createdDate);
        if (byDate != 0) return byDate;
        return (int.tryParse(b.id) ?? 0).compareTo(int.tryParse(a.id) ?? 0);
      });
    return list;
  }

  // ---------------------------------------------------------------------------
  // BELUM disambungkan ke API (langkah berikutnya)
  // ---------------------------------------------------------------------------

  /// Form "Add Observation" — nanti `POST /api/data/observation`.
  Future<ObservationItem> add({
    required String category,
    String? subCategory,
    required DateTime dateFinding,
    required int idDept,
    required String location,
    required String description,
    String? imagePath,
  }) async =>
      throw const ApiException.server(_notConnected);

  /// Form "Edit Observation" — nanti `POST /api/data/observation/{id}`.
  Future<ObservationItem> update(
    String id, {
    required String category,
    String? subCategory,
    required DateTime dateFinding,
    required int idDept,
    required String location,
    required String description,
    String? imagePath,
  }) async =>
      throw const ApiException.server(_notConnected);

  /// Hapus — nanti `DELETE /api/data/observation/{id}`.
  Future<void> delete(String id) async =>
      throw const ApiException.server(_notConnected);

  /// Form "Close Observation" — nanti `POST /api/data/observation/{id}/close`.
  Future<ObservationItem> close(
    String id, {
    required String reason,
    String? imagePath,
  }) async =>
      throw const ApiException.server(_notConnected);
}
