import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../logging/app_logger.dart';
import 'api_config.dart';
import 'api_exception.dart';

/// Satu-satunya tempat di aplikasi yang tahu soal base URL, header, batas
/// waktu, dan bentuk amplop respons BIIE Portal.
///
/// Server selalu membungkus hasilnya seperti ini:
///
/// ```json
/// { "code": 200, "status": "success", "message": "...", "data": { ... } }
/// ```
///
/// Amplop itu dibuka di sini, jadi pemanggil cukup berurusan dengan isi
/// `data` dan dengan [ApiException] bila gagal.
class ApiClient {
  ApiClient({http.Client? httpClient, Duration? timeout})
      : _httpClient = httpClient ?? http.Client(),
        _timeout = timeout ?? ApiConfig.timeout;

  final http.Client _httpClient;
  final Duration _timeout;

  String? _authorizationHeader;

  /// Token yang dipakai untuk request berikutnya. [token] null membuat
  /// client kembali anonim.
  ///
  /// [tokenType] diambil dari respons login (`token_type`), bukan dipatok,
  /// supaya tetap benar kalau server suatu saat menggantinya.
  void setToken(String? token, {String tokenType = 'Bearer'}) {
    _authorizationHeader = token == null ? null : '$tokenType $token';
  }

  String? get authorizationHeader => _authorizationHeader;

  /// Mengirim POST dan mengembalikan isi `data` dari amplop respons.
  ///
  /// Melempar [ApiException] untuk semua kegagalan — jaringan, kredensial,
  /// validasi, maupun respons yang tidak bisa dipahami.
  Future<Map<String, dynamic>> post(
    String path, {
    Map<String, dynamic>? body,
    bool authenticated = true,
  }) {
    final uri = _uriFor(path);
    AppLogger.info('POST $uri ${_redactedBody(body)}');

    return _send(
      'POST',
      uri,
      () => _httpClient.post(
        uri,
        headers: _headers(authenticated: authenticated),
        body: jsonEncode(body ?? const <String, dynamic>{}),
      ),
    ).then((envelope) => _expectMap(envelope['data'], 'POST', uri));
  }

  /// Mengirim `multipart/form-data` — dipakai endpoint yang menerima berkas,
  /// mis. `POST /api/portal/hr_announcement` dengan `photos[]`.
  ///
  /// [files] memetakan nama field ke daftar path berkas, sehingga beberapa
  /// berkas bisa dikirim di bawah satu nama field seperti `photos[]`.
  Future<Map<String, dynamic>> postMultipart(
    String path, {
    Map<String, String>? fields,
    Map<String, List<String>>? files,
  }) {
    final uri = _uriFor(path);
    final fileCount =
        files?.values.fold<int>(0, (sum, paths) => sum + paths.length) ?? 0;
    AppLogger.info(
      'POST $uri (multipart) ${_redactedBody(fields)} · $fileCount berkas',
    );

    return _send(
      'POST',
      uri,
      () async {
        final request = http.MultipartRequest('POST', uri)
          ..headers.addAll(_headers(authenticated: true, json: false));

        if (fields != null) request.fields.addAll(fields);

        for (final entry
            in files?.entries ?? const <MapEntry<String, List<String>>>[]) {
          for (final filePath in entry.value) {
            request.files.add(
              await http.MultipartFile.fromPath(entry.key, filePath),
            );
          }
        }

        return http.Response.fromStream(await _httpClient.send(request));
      },
    ).then((envelope) => _expectMap(envelope['data'], 'POST', uri));
  }

  /// Mengirim GET dan mengembalikan isi `data` dari amplop respons, sebagai
  /// objek. Untuk endpoint yang `data`-nya berupa list (mis. data referensi
  /// seperti daftar departemen), pakai [getList].
  Future<Map<String, dynamic>> get(
    String path, {
    bool authenticated = true,
  }) {
    final uri = _uriFor(path);
    AppLogger.info('GET $uri');

    return _send(
      'GET',
      uri,
      () => _httpClient.get(
        uri,
        headers: _headers(authenticated: authenticated),
      ),
    ).then((envelope) => _expectMap(envelope['data'], 'GET', uri));
  }

  /// Mengirim GET dan mengembalikan **seluruh amplop**, bukan hanya isi `data`.
  ///
  /// Sebagian endpoint menaruh keterangan tambahan bersebelahan dengan `data`,
  /// bukan di dalamnya — mis. `GET /api/portal/apps/eprocurement` yang
  /// mengirim `summary` (jumlah PR per status) dan `meta` (paginasi) sebagai
  /// kunci sejajar. Lewat [get] atau [getList] keduanya akan terbuang.
  ///
  /// Pemeriksaan galat dan keberadaan `data` tetap sama seperti [get].
  Future<Map<String, dynamic>> getEnvelope(
    String path, {
    bool authenticated = true,
  }) {
    final uri = _uriFor(path);
    AppLogger.info('GET $uri');

    return _send(
      'GET',
      uri,
      () => _httpClient.get(
        uri,
        headers: _headers(authenticated: authenticated),
      ),
    );
  }

  /// Mengirim GET dan mengembalikan isi `data` dari amplop respons, sebagai
  /// list — dipakai untuk endpoint data referensi seperti
  /// `GET /api/data/department`, yang menaruh array langsung di `data`
  /// (bukan di dalam objek pembungkus lagi).
  Future<List<dynamic>> getList(
    String path, {
    bool authenticated = true,
  }) {
    final uri = _uriFor(path);
    AppLogger.info('GET $uri');

    return _send(
      'GET',
      uri,
      () => _httpClient.get(
        uri,
        headers: _headers(authenticated: authenticated),
      ),
    ).then((envelope) => _expectList(envelope['data'], 'GET', uri));
  }

  /// GET untuk endpoint yang badan respons-nya langsung berupa array, tanpa
  /// amplop — mis. `GET /api/indent/admin/list_driver`. Kalau server ternyata
  /// membungkusnya `{data: [...]}`, isinya tetap diambil.
  Future<List<dynamic>> getRawList(
    String path, {
    bool authenticated = true,
  }) async {
    final uri = _uriFor(path);
    AppLogger.info('GET $uri');

    final response = await _sendRaw(
      'GET',
      uri,
      () => _httpClient.get(
        uri,
        headers: _headers(authenticated: authenticated),
      ),
    );

    final status = response.statusCode;
    if (status < 200 || status >= 300) {
      // Galat tetap lewat jalur lama supaya jenis & pesannya konsisten
      // (401 -> unauthorized, 422 -> badRequest, dst.). Baris ini selalu
      // melempar; `throw` di bawahnya hanya untuk memuaskan compiler.
      _unwrap(response);
      throw const ApiException.server();
    }

    Object? decoded;
    try {
      decoded = jsonDecode(response.body);
    } on FormatException {
      decoded = null;
    }

    if (decoded is List) return decoded;
    if (decoded is Map<String, dynamic> && decoded['data'] is List) {
      return decoded['data'] as List<dynamic>;
    }

    _logShapeMismatch('GET', uri, 'list', decoded);
    throw const ApiException.server();
  }

    /// POST untuk endpoint yang TIDAK memakai amplop respons — badannya
  /// langsung baris model, mis. `approve_hod` dan `reject_hod`. Respons
  /// itu memuat `"status": 0` (status indent), yang bila dibuka seperti
  /// amplop dianggap gagal. Di sini hanya status HTTP yang diperiksa;
  /// isi respons tidak dipakai.
  Future<void> postRaw(
    String path, {
    Map<String, dynamic>? body,
    bool authenticated = true,
  }) async {
    final uri = _uriFor(path);
    AppLogger.info('POST $uri ${_redactedBody(body)}');

    final response = await _sendRaw(
      'POST',
      uri,
      () => _httpClient.post(
        uri,
        headers: _headers(authenticated: authenticated),
        body: jsonEncode(body ?? const <String, dynamic>{}),
      ),
    );

    final status = response.statusCode;
    if (status < 200 || status >= 300) {
      // Galat tetap lewat jalur lama supaya jenis & pesannya konsisten.
      // Baris ini selalu melempar; `throw` di bawahnya hanya untuk compiler.
      _unwrap(response);
      throw const ApiException.server();
    }
  }

    /// POST untuk aksi yang isi responsnya tidak dipakai, mis. approve /
  /// revision / reject PR. Yang dicek hanya keberhasilannya; `data` boleh
  /// apa saja atau tidak ada. Badan respons dicatat utuh karena bentuknya
  /// belum pernah teramati.
  Future<void> postAction(
    String path, {
    Map<String, dynamic>? body,
    bool authenticated = true,
  }) async {
    final uri = _uriFor(path);
    AppLogger.info('POST $uri ${_redactedBody(body)}');

    final response = await _sendRaw(
      'POST',
      uri,
      () => _httpClient.post(
        uri,
        headers: _headers(authenticated: authenticated),
        body: jsonEncode(body ?? const <String, dynamic>{}),
      ),
    );

    final status = response.statusCode;
    if (status < 200 || status >= 300) {
      _unwrap(response); // selalu melempar (401/403/422/5xx)
      throw const ApiException.server();
    }

    AppLogger.info('Respons aksi $uri: ${_truncate(response.body)}');

    // `status` di amplop sengaja hanya dianggap gagal bila eksplisit gagal.
    // Bisa saja isinya status dokumen (mis. "approved"), bukan status HTTP,
    // dan itu tidak boleh dibaca sebagai kegagalan.
    final envelope = _decode(response.body);
    final s = envelope?['status'];
    final explicitFailure = (s is num && s >= 400) ||
        (s is String && const {'error', 'fail', 'failed'}.contains(s.toLowerCase()));
    if (explicitFailure) {
      throw ApiException(
        ApiErrorKind.server,
        _messageFrom(envelope) ?? const ApiException.server().message,
      );
    }
  }

  /// DELETE tanpa mengharapkan isi: dipakai endpoint yang membalas ringkas,
  /// mis. `DELETE /api/indent/{id}` -> `{"message":"success","status":200,
  /// "data":true}`. Yang dicek hanya keberhasilannya; `data` boleh bentuk apa
  /// saja. Melempar [ApiException] bila gagal.
  Future<void> delete(
    String path, {
    bool authenticated = true,
  }) async {
    final uri = _uriFor(path);
    AppLogger.info('DELETE $uri');

    final response = await _sendRaw(
      'DELETE',
      uri,
      () => _httpClient.delete(
        uri,
        headers: _headers(authenticated: authenticated),
      ),
    );

    final status = response.statusCode;
    if (status < 200 || status >= 300) {
      // Galat lewat jalur yang sama dengan request lain (401, 404, 422, ...).
      // Baris ini selalu melempar; `throw` di bawahnya hanya untuk compiler.
      _unwrap(response);
      throw const ApiException.server();
    }

    // HTTP 2xx tapi amplopnya bisa tetap mengabarkan gagal, mis.
    // {"message":"Indent not found","status":404}.
    final envelope = _decode(response.body);
    if (envelope != null &&
        envelope.containsKey('status') &&
        !_isSuccessStatus(envelope['status'])) {
      AppLogger.info('Amplop menandai gagal: ${_truncate(response.body)}');
      throw ApiException(
        ApiErrorKind.server,
        _messageFrom(envelope) ?? const ApiException.server().message,
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Pembantu internal (private)
  // ---------------------------------------------------------------------------

  /// Badan request untuk keperluan log, dengan field rahasia disamarkan.
  /// Password tidak boleh pernah sampai ke console atau berkas log.
  String _redactedBody(Map<String, dynamic>? body) {
    if (body == null || body.isEmpty) return '';

    const secretKeys = {
      'password',
      'password_confirmation',
      'current_password',
      'new_password',
      'new_password_confirmation',
      'token',
    };
    final safe = {
      for (final entry in body.entries)
        entry.key:
            secretKeys.contains(entry.key.toLowerCase()) ? '***' : entry.value,
    };
    return jsonEncode(safe);
  }

  Uri _uriFor(String path) => Uri.parse('${ApiConfig.baseUrl}$path');

  /// [json] dimatikan untuk multipart: Content-Type di sana harus disusun
  /// http sendiri karena memuat boundary.
  Map<String, String> _headers({
    required bool authenticated,
    bool json = true,
  }) {
    final header = _authorizationHeader;
    return {
      if (json) 'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (authenticated && header != null) 'Authorization': header,
    };
  }

  /// Menjalankan request lalu menerjemahkan setiap cara gagalnya menjadi
  /// [ApiException].
  Future<http.Response> _sendRaw(
    String method,
    Uri uri,
    Future<http.Response> Function() request,
  ) async {
    final http.Response response;
    try {
      response = await request().timeout(_timeout);
    } on TimeoutException catch (e, stack) {
      AppLogger.error('$method $uri melewati batas waktu', e, stack);
      throw const ApiException.timeout();
    } on SocketException catch (e, stack) {
      AppLogger.error('$method $uri gagal menghubungi server', e, stack);
      throw const ApiException.network();
    } on http.ClientException catch (e, stack) {
      AppLogger.error('$method $uri gagal menghubungi server', e, stack);
      throw const ApiException.network();
    }

    final status = response.statusCode;
    if (status >= 200 && status < 300) {
      AppLogger.info('$method $uri -> $status');
    } else {
      // Badan respons galat sengaja ikut dicatat: di situlah pesan server
      // berada, dan itu yang paling menolong saat melacak masalah.
      AppLogger.info('$method $uri -> $status ${_truncate(response.body)}');
    }

    return response;
  }

  /// Kirim, lalu buka amplop {code,status,data}.
  Future<Map<String, dynamic>> _send(
    String method,
    Uri uri,
    Future<http.Response> Function() request,
  ) async =>
      _unwrap(await _sendRaw(method, uri, request));

  String _truncate(String body, [int max = 500]) =>
      body.length <= max ? body : '${body.substring(0, max)}…';

  /// Memeriksa amplop respons, atau melempar [ApiException] yang sesuai.
  ///
  /// Mengembalikan amplopnya utuh — bukan hanya `data` — karena sebagian
  /// endpoint menaruh keterangan lain di sampingnya (lihat [getEnvelope]).
  /// Pemanggil yang hanya butuh isinya memetik `['data']` sendiri, lalu
  /// menentukan bentuk yang diharapkan lewat [_expectMap] / [_expectList].
  Map<String, dynamic> _unwrap(http.Response response) {
    final envelope = _decode(response.body);
    final serverMessage = _messageFrom(envelope);
    final status = response.statusCode;

    if (status == 401 || status == 403) {
      throw ApiException(
        ApiErrorKind.unauthorized,
        serverMessage ?? const ApiException.unauthorized().message,
      );
    }

    if (status == 422 || status == 400) {
      throw ApiException(
        ApiErrorKind.badRequest,
        _firstValidationError(envelope) ??
            serverMessage ??
            const ApiException.badRequest().message,
      );
    }

    if (status < 200 || status >= 300) {
      throw ApiException(
        ApiErrorKind.server,
        serverMessage ?? const ApiException.server().message,
      );
    }

    // HTTP 2xx, tapi badan respons masih bisa mengabarkan kegagalan. Isi
    // badannya ikut dicatat: tanpa itu, kegagalan bentuk pada respons sukses
    // hanya terlihat sebagai "gangguan server" tanpa petunjuk apa pun.
    if (envelope == null) {
      AppLogger.info(
        'Badan respons bukan objek JSON: ${_truncate(response.body)}',
      );
      throw const ApiException.server();
    }

    // Tidak semua endpoint memakai amplop lengkap. `POST /api/login` mengirim
    // {code, status, message, data}, sementara endpoint data referensi seperti
    // `GET /api/data/department` hanya mengirim {data}. Karena itu `status`
    // hanya diperiksa kalau memang dikirim — ketiadaannya bukan tanda gagal.
    if (envelope.containsKey('status') &&
        !_isSuccessStatus(envelope['status'])) {
      AppLogger.info(
        'Amplop menandai gagal: ${_truncate(response.body)}',
      );
      throw ApiException(
        ApiErrorKind.server,
        serverMessage ?? const ApiException.server().message,
      );
    }

    if (!envelope.containsKey('data')) {
      AppLogger.info(
        'Amplop tidak memuat data: ${_truncate(response.body)}',
      );
      throw const ApiException.server();
    }

    return envelope;
  }

  /// `status` di amplop bisa berupa kata 'success' (login, dll.) atau angka
  /// HTTP seperti 200 (Indent Vehicle). Keduanya berarti sukses.
  bool _isSuccessStatus(dynamic status) =>
      status == 'success' || (status is num && status >= 200 && status < 300);

  /// Memastikan `data` berbentuk objek, untuk [post] dan [get].
  Map<String, dynamic> _expectMap(dynamic data, String method, Uri uri) {
    if (data is! Map<String, dynamic>) {
      _logShapeMismatch(method, uri, 'objek', data);
      throw const ApiException.server();
    }
    return data;
  }

  /// Memastikan `data` berbentuk list, untuk [getList].
  List<dynamic> _expectList(dynamic data, String method, Uri uri) {
    if (data is! List) {
      _logShapeMismatch(method, uri, 'list', data);
      throw const ApiException.server();
    }
    return data;
  }

  /// Mencatat bentuk `data` yang sebenarnya datang saat tidak sesuai harapan.
  /// Isinya ikut dicatat supaya struktur aslinya langsung terbaca.
  void _logShapeMismatch(
    String method,
    Uri uri,
    String expected,
    dynamic data,
  ) {
    AppLogger.info(
      '$method $uri -> data seharusnya $expected, '
      'yang datang ${data.runtimeType}: ${_truncate(jsonEncode(data))}',
    );
  }

  /// Mem-parsing badan respons sebagai objek JSON. Mengembalikan null bila
  /// badannya kosong, bukan JSON (misalnya halaman error HTML), atau bukan
  /// objek.
  Map<String, dynamic>? _decode(String body) {
    if (body.isEmpty) return null;
    try {
      final decoded = jsonDecode(body);
      return decoded is Map<String, dynamic> ? decoded : null;
    } on FormatException {
      return null;
    }
  }

  String? _messageFrom(Map<String, dynamic>? envelope) {
    final message = envelope?['message'];
    return message is String && message.isNotEmpty ? message : null;
  }

  /// Mengambil pesan validasi pertama dari `errors` bergaya Laravel:
  /// `{"errors": {"email": ["Email tidak terdaftar."]}}`.
  String? _firstValidationError(Map<String, dynamic>? envelope) {
    final errors = envelope?['errors'];
    if (errors is! Map || errors.isEmpty) return null;

    final first = errors.values.first;
    if (first is List && first.isNotEmpty && first.first is String) {
      return first.first as String;
    }
    return first is String ? first : null;
  }
}
