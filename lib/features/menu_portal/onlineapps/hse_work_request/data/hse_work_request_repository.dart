import '../../../../../core/network/api_client.dart';
import '../../../../../core/network/api_config.dart';
import '../../../../../core/network/api_exception.dart';
import '../domain/hse_form_options.dart';
import '../domain/hse_permit_page.dart';
import '../domain/hse_request_status.dart';
import '../domain/hse_work_request.dart';

/// Hasil aksi yang mengubah permit: pesan dari server + permit terbaru.
typedef HsePermitResult = ({String message, HseWorkRequest permit});

/// Akses API HSE Work Permit (`/api/portal/apps/hse_permit`).
///
/// Semua method melempar [ApiException] bila gagal; pesan validasi 422
/// (mis. dokumen NON-RUTIN belum lengkap) sudah siap ditampilkan.
class HseWorkRequestRepository {
  HseWorkRequestRepository({required ApiClient apiClient})
      : _apiClient = apiClient;

  final ApiClient _apiClient;

  /// Isi dropdown & checklist form — `GET /hse_permit/options`.
  Future<HseFormOptions> fetchOptions() async {
    final data = await _apiClient.get(ApiConfig.hsePermitOptions);
    return HseFormOptions.fromJson(data);
  }

  /// Daftar permit — `GET /hse_permit`.
  ///
  /// Tanpa [status], server menampilkan semua permit KECUALI yang Reject.
  /// [mine] membatasi ke permit milik user yang login.
  Future<HsePermitPage> fetchPermits({
    int page = 1,
    int perPage = 20,
    HseRequestStatus? status,
    bool mine = false,
  }) async {
    final envelope = await _apiClient.getEnvelope(
      _withQuery(ApiConfig.hsePermit, {
        'page': '$page',
        'per_page': '$perPage',
        if (status != null) 'status': status.toApi(),
        if (mine) 'mine': '1',
      }),
    );
    return HsePermitPage.fromEnvelope(envelope);
  }

  /// Detail lengkap (checklist, dokumen, closing) — `GET /hse_permit/{id}`.
  Future<HseWorkRequest> fetchDetail(int id) async {
    final data = await _apiClient.get(ApiConfig.hsePermitDetail(id));
    return _parse(data);
  }

  /// Mengajukan permit — `POST /hse_permit`.
  ///
  /// Selalu dikirim multipart: NON-RUTIN wajib begitu (ada 3 PDF), dan
  /// RUTIN juga diterima server dalam bentuk form.
  Future<HsePermitResult> submit(HsePermitDraft draft) async {
    final body = await _apiClient.postMultipartJson(
      ApiConfig.hsePermit,
      fields: draft.toFields(),
      files: {
        for (final entry in draft.documents.entries) entry.key: [entry.value],
      },
    );
    return _result(body, 'HSE work permit submitted.');
  }

  /// Antrean approval — `GET /hse_permit/approvals`.
  ///
  /// [stage] `hod` / `hse`; null = semua stage milik user. Akun yang bukan
  /// approver dibalas 403 (`ApiErrorKind.unauthorized`).
  Future<HsePermitPage> fetchApprovals({
    String? stage,
    int page = 1,
    int perPage = 100,
  }) async {
    final envelope = await _apiClient.getEnvelope(
      _withQuery(ApiConfig.hsePermitApprovals, {
        'page': '$page',
        'per_page': '$perPage',
        if (stage != null) 'stage': stage,
      }),
    );
    return HsePermitPage.fromEnvelope(envelope);
  }

  /// `POST /hse_permit/{id}/approve` (tanpa body).
  Future<HsePermitResult> approve(int id) async {
    final body = await _apiClient.postJson(ApiConfig.hsePermitApprove(id));
    return _result(body, 'HSE work permit approved.');
  }

  /// `POST /hse_permit/{id}/reject` (tanpa body — alasan belum didukung).
  Future<HsePermitResult> reject(int id) async {
    final body = await _apiClient.postJson(ApiConfig.hsePermitReject(id));
    return _result(body, 'HSE work permit rejected.');
  }

  /// Menutup permit On Progress milik sendiri — `POST /hse_permit/{id}/close`.
  /// [evidencePath]: jpeg/jpg/png/gif/pdf, maks 10 MB.
  Future<HsePermitResult> close(
    int id, {
    required String description,
    required String evidencePath,
  }) async {
    final body = await _apiClient.postMultipartJson(
      ApiConfig.hsePermitClose(id),
      fields: {'description': description.trim()},
      files: {
        'evidence': [evidencePath],
      },
    );
    return _result(body, 'HSE work permit closed.');
  }

  /// Menghapus permit milik sendiri yang masih waiting —
  /// `DELETE /hse_permit/{id}`. Mengembalikan pesan dari server.
  Future<String> delete(int id) async {
    final body = await _apiClient.deleteJson(ApiConfig.hsePermitDetail(id));
    return _message(body) ?? 'HSE work permit deleted.';
  }

  HsePermitResult _result(Map<String, dynamic> body, String fallback) {
    final data = body['data'];
    if (data is! Map<String, dynamic>) throw const ApiException.server();
    return (message: _message(body) ?? fallback, permit: _parse(data));
  }

  HseWorkRequest _parse(Map<String, dynamic> data) {
    try {
      return HseWorkRequest.fromJson(data);
    } on FormatException {
      throw const ApiException.server(
        'The server response for this permit was not recognized.',
      );
    }
  }

  static String? _message(Map<String, dynamic> body) {
    final message = body['message'];
    return message is String && message.isNotEmpty ? message : null;
  }

  static String _withQuery(String path, Map<String, String> query) =>
      Uri(path: path, queryParameters: query).toString();
}
