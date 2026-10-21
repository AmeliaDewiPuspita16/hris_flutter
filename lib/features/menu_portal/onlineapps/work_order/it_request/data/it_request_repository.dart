import '../../../../../../core/network/api_client.dart';
import '../../../../../../core/network/api_config.dart';
import '../../../../../../core/network/api_exception.dart';
import '../domain/it_request_detail.dart';
import '../domain/it_request_page.dart';
import '../domain/it_request_type.dart';
import '../domain/support_type.dart';

/// Riwayat IT/Media Request milik user sendiri. Tidak tahu soal HTTP — itu
/// urusan [ApiClient].
class ItRequestRepository {
  ItRequestRepository({required ApiClient apiClient}) : _apiClient = apiClient;

  final ApiClient _apiClient;

  /// Satu halaman riwayat request, beserta jumlah yang menunggu rating dan
  /// paginasinya.
  ///
  /// [status] (mis. `waiting`, `progress`) menyaring di sisi server lewat
  /// `?status=` — `meta.total` pada hasilnya pun jadi jumlah request
  /// berstatus itu saja, cocok untuk counter di tab "List Request".
  ///
  /// Melempar [ApiException] bila gagal.
  Future<ItRequestPage> fetchList({
    int page = 1,
    int perPage = 20,
    String? status,
  }) async {
    final envelope = await _apiClient.getEnvelope(
      _pathWithQuery(ApiConfig.itRequest, {
        'page': '$page',
        'per_page': '$perPage',
        if (status != null) 'status': status,
      }),
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
        'The request detail was received, but its content was not recognized.',
      );
    }
  }

  /// Mengajukan request IT/Media baru.
  ///
  /// [categoryFields] adalah field tambahan spesifik kategori yang sudah
  /// diresolusi ke nama field server (mis. `hardware_need_laptop: '1'`,
  /// `download_desc: 'Figma Desktop'`) — pemetaan dari pilihan form ke nama
  /// field itu tanggung jawab pemanggil (lihat `NeedOption` di domain),
  /// bukan repository ini, supaya "kategori mana butuh field apa" hanya
  /// hidup di satu tempat.
  ///
  /// Bentuk `data` pada respons 201 sama persis dengan
  /// `GET /api/portal/apps/it_request/{id}`, jadi dipetakan lewat
  /// [ItRequestDetail.fromJson] yang sama — layar pemanggil bisa langsung
  /// memakai hasilnya tanpa fetch ulang.
  ///
  /// Melempar [ApiException] bila gagal, termasuk galat validasi (pesan
  /// dari field yang salah pertama, lihat `ApiClient._firstValidationError`).
  Future<ItRequestDetail> submit({
    required ItRequestType type,
    required SupportType supportType,
    required String requestCategoryCode,
    required String description,
    Map<String, String> categoryFields = const {},
    String? imagePath,
  }) async {
    final data = await _apiClient.postMultipart(
      ApiConfig.itRequest,
      fields: {
        'type_request': type.formValue,
        'jenis_dukungan': supportType.wireValue,
        'request_category': requestCategoryCode,
        'deskripsi': description,
        ...categoryFields,
      },
      files: imagePath == null ? null : {'image': [imagePath]},
    );

    try {
      return ItRequestDetail.fromJson(data);
    } on FormatException {
      throw const ApiException.server(
        'The request was submitted, but the server response was not recognized.',
      );
    }
  }

  /// Mengirim rating 1–5 bintang + catatan opsional untuk request yang
  /// sudah selesai dikerjakan.
  ///
  /// Bentuk `data` pada respons sama persis dengan `GET .../{id}`, jadi
  /// dipetakan lewat [ItRequestDetail.fromJson] yang sama — pemanggil bisa
  /// langsung memakai `canRate`/`rating`/`ratingComment` terbaru dari server
  /// tanpa fetch ulang.
  ///
  /// Melempar [ApiException] bila gagal, termasuk galat validasi.
  Future<ItRequestDetail> submitRating(
    int id, {
    required int star,
    String? message,
  }) async {
    final data = await _apiClient.post(
      '${ApiConfig.itRequest}/$id/rating',
      body: {'star': star, 'message': message},
    );

    try {
      return ItRequestDetail.fromJson(data);
    } on FormatException {
      throw const ApiException.server(
        'The rating was submitted, but the server response was not recognized.',
      );
    }
  }

  /// Dipanggil tim IT untuk merespons request yang masih "On Waiting" —
  /// server otomatis mengubah statusnya jadi "On Progress" begitu respons
  /// ini tersimpan.
  ///
  /// Bentuk `data` sama dengan `GET .../{id}`, jadi dipetakan lewat
  /// [ItRequestDetail.fromJson] yang sama.
  ///
  /// Melempar [ApiException] bila gagal, termasuk galat validasi (mis.
  /// `note` kosong) atau karena user bukan tim IT.
  Future<ItRequestDetail> respond(int id, {required String note}) async {
    final data = await _apiClient.post(
      '${ApiConfig.itRequest}/$id/respond',
      body: {'note': note},
    );

    try {
      return ItRequestDetail.fromJson(data);
    } on FormatException {
      throw const ApiException.server(
        'Respons terkirim, tapi respons server tidak dikenali.',
      );
    }
  }

  /// Dipanggil tim IT untuk menutup request yang "On Progress" dengan foto
  /// bukti pengerjaan. Status di server berubah jadi "Wait Checked" — BUKAN
  /// langsung "Done", karena "Done" baru tercapai lewat langkah verifikasi
  /// terpisah (lih. `Checking`).
  ///
  /// Wajib `multipart/form-data` karena ada berkas foto. Bentuk `data` sama
  /// dengan `GET .../{id}`, jadi dipetakan lewat [ItRequestDetail.fromJson]
  /// yang sama.
  ///
  /// Melempar [ApiException] bila gagal, termasuk galat validasi (mis. foto
  /// tidak disertakan).
  Future<ItRequestDetail> complete(
    int id, {
    required String photoPath,
    String? note,
  }) async {
    final data = await _apiClient.postMultipart(
      '${ApiConfig.itRequest}/$id/complete',
      fields: {
        if (note != null && note.isNotEmpty) 'note': note,
      },
      files: {'photo': [photoPath]},
    );

    try {
      return ItRequestDetail.fromJson(data);
    } on FormatException {
      throw const ApiException.server(
        'Foto terkirim, tapi respons server tidak dikenali.',
      );
    }
  }

  static String _pathWithQuery(String path, Map<String, String> query) =>
      Uri(path: path, queryParameters: query).toString();
}
