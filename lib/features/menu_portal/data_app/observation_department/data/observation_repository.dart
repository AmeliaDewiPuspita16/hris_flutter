import '../../../../../core/logging/app_logger.dart';
import '../../../../../core/network/api_client.dart';
import '../../../../../core/network/api_config.dart';
import '../../../../../core/network/api_exception.dart';
import '../../../../../core/network/page_meta.dart';
import '../domain/observation_item.dart';
import '../domain/observation_options.dart';
import '../domain/observation_page.dart';

/// Pintu ke API Observation Department:
///
/// - [fetchAll] — `GET /api/data/observation` (per halaman, dengan filter).
/// - [fetchOpenFromMyDept] — `GET /api/data/observation/requests`.
/// - [fetchDetail] — `GET /api/data/observation/{id}`.
/// - [fetchOptions] — `GET /api/data/observation/options`.
/// - [add] — `POST /api/data/observation`.
/// - [update] — `POST /api/data/observation/{id}`.
/// - [delete] — `DELETE /api/data/observation/{id}`.
/// - [close] — `POST /api/data/observation/{id}/close`.
///
/// Pencarian, filter, dan paginasi daftar dikerjakan server; aplikasi hanya
/// meminta satu halaman setiap kali.
class ObservationRepository {
  ObservationRepository({required ApiClient apiClient})
      : _apiClient = apiClient;

  final ApiClient _apiClient;

  /// Jumlah baris per halaman (server menerima 1-100).
  static const pageSize = 20;

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
          'The form options were received, but their format was not recognized.');
    }
  }

  /// Tabel "All Observations": satu halaman observasi, terbaru di atas.
  ///
  /// Semua parameter opsional dan dikirim ke server: [search] (lokasi,
  /// kategori, deskripsi, pelapor, departemen), [month] (hanya tahun dan
  /// bulan yang dipakai), [idDept] (departemen tujuan, dari `/options`), dan
  /// [category]. Melempar [ApiException] bila request gagal.
  Future<ObservationPage> fetchAll({
    int page = 1,
    String? search,
    DateTime? month,
    int? idDept,
    String? category,
  }) {
    return _fetchPage(
      ApiConfig.observation,
      page: page,
      search: search,
      filters: {
        if (month != null) 'month': _apiMonth(month),
        if (idDept != null) 'id_dept': '$idDept',
        if (category != null) 'category': category,
      },
    );
  }

  /// Tab "To Close": satu halaman temuan berstatus open yang ditujukan ke
  /// departemen user atau dibuat oleh user sendiri. Hanya yang
  /// `can_close = true` yang mendapat tombol Close. `ObservationPage.meta.total`
  /// adalah angka untuk badge tab.
  Future<ObservationPage> fetchOpenFromMyDept({
    int page = 1,
    String? search,
  }) {
    return _fetchPage(ApiConfig.observationRequests, page: page, search: search);
  }

  /// Satu temuan lewat `GET /api/data/observation/{id}` — dipakai untuk
  /// temuan dari notifikasi yang belum ikut termuat di daftar.
  Future<ObservationItem> fetchDetail(String id) async {
    final numericId = int.tryParse(id);
    if (numericId == null) {
      throw const ApiException.server('Invalid observation id.');
    }
    final data = await _apiClient.get(ApiConfig.observationDetail(numericId));
    try {
      return ObservationItem.fromJson(data);
    } on FormatException catch (e) {
      AppLogger.info('Detail observation tidak terbaca: ${e.message}');
      throw const ApiException.server(
        'The observation was received, but its format was not recognized.',
      );
    }
  }

  Future<ObservationPage> _fetchPage(
    String path, {
    required int page,
    String? search,
    Map<String, String> filters = const {},
  }) async {
    final keyword = search?.trim() ?? '';
    final envelope = await _apiClient.getEnvelope(
      Uri(
        path: path,
        queryParameters: {
          ...filters,
          if (keyword.isNotEmpty) 'search': keyword,
          'per_page': '$pageSize',
          'page': '$page',
        },
      ).toString(),
    );

    final rows = envelope['data'];
    if (rows is! List) {
      throw const ApiException.server(
        'The observation list was received, but its format was not recognized.',
      );
    }

    final items = <ObservationItem>[];
    for (final row in rows.whereType<Map<String, dynamic>>()) {
      try {
        items.add(ObservationItem.fromJson(row));
      } on FormatException catch (e) {
        // Satu baris rusak tidak boleh menggagalkan seluruh halaman.
        AppLogger.info('Observation dilewati: ${e.message}');
      }
    }

    // Amplop tanpa `meta` dibaca sebagai satu halaman penuh (lihat PageMeta).
    final meta = envelope['meta'];
    return ObservationPage(
      items: items,
      meta: PageMeta.fromJson(
        meta is Map<String, dynamic> ? meta : const <String, dynamic>{},
      ),
    );
  }

  /// `YYYY-MM` seperti yang diminta server untuk filter `month`.
  String _apiMonth(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}';

  /// Form "Add Observation": `POST /api/data/observation` (multipart).
  ///
  /// [subCategory] hanya dikirim bila ada (praktis hanya Safety). [imagePath]
  /// adalah path berkas lokal; dikirim sebagai `image_finding`. Pelanggaran
  /// aturan (mis. foto wajib) dibalas 422 dan muncul sebagai [ApiException]
  /// dengan pesan dari server. Isi balasan 201 tidak dibaca: layar memuat
  /// ulang daftar, dan menolak balasan yang aneh justru mengundang kirim
  /// ulang padahal data sudah tersimpan.
  Future<void> add({
    required String category,
    String? subCategory,
    required DateTime dateFinding,
    required int idDept,
    required String location,
    required String description,
    String? imagePath,
  }) async {
    await _apiClient.postMultipart(
      ApiConfig.observation,
      fields: _formFields(
        category: category,
        subCategory: subCategory,
        dateFinding: dateFinding,
        idDept: idDept,
        location: location,
        description: description,
      ),
      files: _imageFiles(imagePath),
    );
  }

  /// Form "Edit Observation": `POST /api/data/observation/{id}` (multipart;
  /// edit memakai POST, bukan PUT/PATCH).
  ///
  /// Field-nya sama dengan [add]. [imagePath] yang berupa URL (foto lama dari
  /// server, `http...`) tidak diunggah ulang: tanpa `image_finding`, server
  /// mempertahankan foto lama. Hanya foto baru dari perangkat yang dikirim.
  Future<void> update(
    String id, {
    required String category,
    String? subCategory,
    required DateTime dateFinding,
    required int idDept,
    required String location,
    required String description,
    String? imagePath,
  }) async {
    await _apiClient.postMultipart(
      ApiConfig.observationDetail(int.parse(id)),
      fields: _formFields(
        category: category,
        subCategory: subCategory,
        dateFinding: dateFinding,
        idDept: idDept,
        location: location,
        description: description,
      ),
      files: _imageFiles(imagePath),
    );
  }

  /// Field teks form Add / Edit (nama field sesuai dokumen API).
  Map<String, String> _formFields({
    required String category,
    String? subCategory,
    required DateTime dateFinding,
    required int idDept,
    required String location,
    required String description,
  }) =>
      {
        'category': category,
        if (subCategory != null) 'finding_category': subCategory,
        'date_finding': _apiDate(dateFinding),
        'id_dept': '$idDept',
        'location': location,
        'description': description,
      };

  /// Berkas yang diunggah: hanya path lokal. URL berarti foto yang sudah ada
  /// di server, jadi tidak dikirim lagi.
  Map<String, List<String>>? _imageFiles(String? imagePath) {
    if (imagePath == null || imagePath.startsWith('http')) return null;
    return {
      'image_finding': [imagePath],
    };
  }

  /// `YYYY-MM-DD` seperti yang diminta server.
  String _apiDate(DateTime date) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${date.year}-${two(date.month)}-${two(date.day)}';
  }

  /// Hapus satu temuan. Hanya berhasil bila server mengizinkan
  /// (`can_delete`); selain itu [ApiException] dengan pesan dari
  /// server (403 tanpa izin, 404 sudah tidak ada).
  Future<void> delete(String id) =>
      _apiClient.delete(ApiConfig.observationDetail(int.parse(id)));

  /// Form "Close Observation": `POST /api/data/observation/{id}/close`
  /// (multipart). [reason] maksimal 255 karakter. [imagePath] (berkas lokal,
  /// dikirim sebagai `image_close`) wajib bila `image_required_to_close`
  /// bernilai true; bila dilanggar server membalas 422 dengan pesannya.
  Future<void> close(
    String id, {
    required String reason,
    String? imagePath,
  }) async {
    await _apiClient.postMultipart(ApiConfig.observationClose(int.parse(id)),
        fields: {'reason_close': reason},
        files: imagePath == null
            ? null
            : {
                'image_close': [imagePath],
              });
  }
}
