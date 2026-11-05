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
/// - [fetchOpenFromMyDept], [add], [update], [delete], [close] — BELUM
///   disambungkan; sementara dibiarkan kosong / melempar galat supaya tidak
///   ada data dummy yang tercampur dengan data asli.
///
/// Instance-nya didaftarkan di `RepositoryProvider` (seperti
/// `IndentVehicleRepository`) dan dipakai bersama layar Add / Detail.
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

  /// Pilihan "Relevant Dept." di form Add. MASIH hardcode — akan diganti
  /// dengan `GET /api/data/observation/options` saat form Add disambungkan.
  /// (Filter di daftar sudah tidak memakai ini.)
  static const departments = <String>[
    'CDD',
    'ENV',
    'EST',
    'HR & GA',
    'HSE',
    'ITM',
  ];

  /// Tabel "All Observations": semua observasi, terbaru di atas.
  ///
  /// Semua halaman diambil sekaligus (mengikuti `meta.last_page`) karena
  /// pencarian dan filter di layar masih dilakukan lokal atas seluruh data.
  /// Melempar [ApiException] bila request gagal.
  Future<List<ObservationItem>> fetchAll() async {
    final items = <ObservationItem>[];
    var page = 1;
    var lastPage = 1;

    do {
      final envelope = await _apiClient.getEnvelope(
        Uri(
          path: ApiConfig.observation,
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

  /// Tab "To Close" — nanti dari `GET /api/data/observation/requests`.
  /// Sementara kosong.
  Future<List<ObservationItem>> fetchOpenFromMyDept() async => const [];

  /// Form "Add Observation" — nanti `POST /api/data/observation`.
  Future<ObservationItem> add({
    required ObservationCategory category,
    String? subCategory,
    required DateTime dateFinding,
    required String relevantDept,
    required String location,
    required String description,
    String? imagePath,
  }) async =>
      throw const ApiException.server(_notConnected);

  /// Form "Edit Observation" — nanti `POST /api/data/observation/{id}`.
  Future<ObservationItem> update(
    String id, {
    required ObservationCategory category,
    String? subCategory,
    required DateTime dateFinding,
    required String relevantDept,
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
