import '../../../../../../core/network/api_client.dart';
import '../../../../../../core/network/api_config.dart';
import '../../../../../../core/network/api_exception.dart';
import '../domain/est_approval_page.dart';
import '../domain/est_request_detail.dart';
import '../domain/est_request_page.dart';
import '../domain/est_request_type.dart';

/// Akses API EST Work Order. Tidak tahu soal HTTP — itu urusan
/// `ApiClient`. Saat ini: daftar All Request, detail, submit (create), edit,
/// hapus, rating, dan antrean approval HOD.
class EstRequestRepository {
  EstRequestRepository({required ApiClient apiClient})
      : _apiClient = apiClient;

  final ApiClient _apiClient;

  /// Daftar Work Order, terbaru di atas — `GET /est_work_order`.
  ///
  /// Berisi request SEMUA user (sama seperti daftar di web); [mine] `true`
  /// membatasi ke milik sendiri. Server memaginasi hasilnya: minta halaman
  /// berikutnya lewat [page], dan cek `meta.hasMore` pada hasilnya.
  ///
  /// [status] (`waiting_hod`, `waiting`, `progress`, `finished`, `rejected`)
  /// dan [type] (`Repair` atau `Project`) menyaring di sisi server.
  ///
  /// Melempar `ApiException` bila gagal.
  Future<EstRequestPage> fetchRequests({
    int page = 1,
    int perPage = 20,
    bool mine = false,
    String? status,
    String? type,
  }) async {
    final envelope = await _apiClient.getEnvelope(
      _pathWithQuery(ApiConfig.estRequest, {
        'page': '$page',
        'per_page': '$perPage',
        if (mine) 'mine': '1',
        if (status != null) 'status': status,
        if (type != null) 'type': type,
      }),
    );

    return EstRequestPage.fromEnvelope(envelope);
  }

  /// Detail satu Work Order — `GET /est_work_order/{id}`.
  ///
  /// Semua user boleh membuka WO siapa pun (mengikuti daftar di web); yang
  /// membedakan hanya flag `can_*` di hasilnya. Melempar `ApiException`
  /// bila gagal, mis. 404 untuk id yang tidak ada.
  Future<EstRequestDetail> fetchDetail(int id) async {
    final data = await _apiClient.get(ApiConfig.estRequestDetail(id));

    return EstRequestDetail.fromJson(data);
  }

  /// Mengajukan Work Order baru — `POST /est_work_order` (multipart).
  ///
  /// Nama & departemen requester tidak dikirim: server memakai user yang
  /// login. Setelah tersimpan, HOD departemen requester mendapat notifikasi
  /// push (diurus server). [imagePath] opsional (png/jpg, maks 2 MB).
  ///
  /// Bentuk `data` pada respons 201 sama dengan `GET /{id}`, jadi dipetakan
  /// lewat [EstRequestDetail.fromJson] yang sama.
  ///
  /// Melempar [ApiException] bila gagal, termasuk galat validasi (pesan dari
  /// field pertama yang salah, lihat `ApiClient._firstValidationError`).
  Future<EstRequestDetail> create({
    required EstRequestType type,
    required String location,
    required String description,
    String? imagePath,
  }) async {
    final data = await _apiClient.postMultipart(
      ApiConfig.estRequest,
      fields: {
        'type': type.label,
        'location': location.trim(),
        'description': description.trim(),
      },
      files: imagePath == null ? null : {'image': [imagePath]},
    );

    try {
      return EstRequestDetail.fromJson(data);
    } on FormatException {
      throw const ApiException.server(
        'The request was submitted, but the server response was not recognized.',
      );
    }
  }

  /// Mengedit Work Order milik sendiri — `POST /est_work_order/{id}`
  /// (multipart, bukan PUT, karena bisa mengganti foto).
  ///
  /// Hanya bisa saat status masih `waiting_hod` (`can_edit = true`); server
  /// membalas 403/422 di luar itu. Tiga kemungkinan untuk foto:
  /// - [imagePath] diisi: foto lama diganti.
  /// - [removeImage] `true` (tanpa [imagePath]): foto lama dihapus.
  /// - keduanya kosong: foto lama tetap dipakai.
  ///
  /// `data` pada respons 200 berisi detail lengkap, dipetakan lewat
  /// [EstRequestDetail.fromJson]. Melempar [ApiException] bila gagal.
  Future<EstRequestDetail> update(
    int id, {
    required EstRequestType type,
    required String location,
    required String description,
    String? imagePath,
    bool removeImage = false,
  }) async {
    final data = await _apiClient.postMultipart(
      ApiConfig.estRequestDetail(id),
      fields: {
        'type': type.label,
        'location': location.trim(),
        'description': description.trim(),
        if (imagePath == null && removeImage) 'remove_image': '1',
      },
      files: imagePath == null ? null : {'image': [imagePath]},
    );

    try {
      return EstRequestDetail.fromJson(data);
    } on FormatException {
      throw const ApiException.server(
        'The request was updated, but the server response was not recognized.',
      );
    }
  }

  /// Menghapus Work Order milik sendiri — `DELETE /est_work_order/{id}`.
  /// Foto WO ikut terhapus di server. Hanya bisa saat `can_delete = true`.
  ///
  /// Melempar [ApiException] bila gagal (403 bukan pemilik, 422 sudah
  /// diproses HOD).
  Future<void> delete(int id) =>
      _apiClient.delete(ApiConfig.estRequestDetail(id));

  /// Verifikasi + rating oleh requester — `POST /est_work_order/{id}/rating`.
  ///
  /// Menutup WO dari sisi requester (sama dengan tombol "Verify Request" di
  /// web); status berubah menjadi `finished`. [star] 1-5, [message] wajib
  /// (maks 1000 karakter). Server membalas 422 bila user bukan pemilik, WO
  /// belum selesai, atau sudah pernah dirating.
  ///
  /// Melempar [ApiException] bila gagal, termasuk galat validasi.
  Future<void> submitRating(
    int id, {
    required int star,
    required String message,
  }) =>
      _apiClient.postAction(
        ApiConfig.estRequestRating(id),
        body: {'star': star, 'message': message.trim()},
      );

  /// Antrean HOD: request dari department-nya yang masih `status = 0`
  /// (menunggu HOD).
  ///
  /// Server memaginasi hasilnya (`meta.current_page/last_page/total`).
  /// Belum ada infinite scroll di tab Approve HOD, jadi [perPage] sengaja
  /// besar — antrean satu department jarang sebanyak itu, dan badge tetap
  /// akurat karena memakai `summary.pending`.
  ///
  /// [type] (`Repair` atau `Project`) menyaring di sisi server lewat
  /// `?type=`.
  ///
  /// Melempar `ApiException` bila gagal (mis. 403 untuk akun bukan HOD).
  Future<EstApprovalPage> fetchApprovals({
    int page = 1,
    int perPage = 100,
    String? type,
  }) async {
    final envelope = await _apiClient.getEnvelope(
      _pathWithQuery(ApiConfig.estRequestApprovals, {
        'page': '$page',
        'per_page': '$perPage',
        if (type != null) 'type': type,
      }),
    );

    return EstApprovalPage.fromEnvelope(envelope);
  }

  /// HOD menyetujui request: status di server jadi 1 dan `approval_hod`
  /// diisi id HOD yang sedang login (server yang mengisi, bukan aplikasi).
  ///
  /// Melempar `ApiException` bila gagal.
  Future<void> approve(int id) =>
      _apiClient.postAction(ApiConfig.estRequestApprove(id));

  /// HOD menolak request: status di server jadi 4. [reason] opsional
  /// (maks 1000 karakter); kosong berarti tidak dikirim sama sekali.
  ///
  /// Melempar `ApiException` bila gagal, termasuk galat validasi.
  Future<void> reject(int id, {String? reason}) => _apiClient.postAction(
        ApiConfig.estRequestReject(id),
        body: {
          if (reason != null && reason.trim().isNotEmpty)
            'reason': reason.trim(),
        },
      );

  static String _pathWithQuery(String path, Map<String, String> query) =>
      Uri(path: path, queryParameters: query).toString();
}
