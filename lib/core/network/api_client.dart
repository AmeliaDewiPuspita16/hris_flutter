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
    ).then((data) => _expectMap(data, 'POST', uri));
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
    ).then((data) => _expectMap(data, 'GET', uri));
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
    ).then((data) => _expectList(data, 'GET', uri));
  }

  /// Badan request untuk keperluan log, dengan field rahasia disamarkan.
  /// Password tidak boleh pernah sampai ke console atau berkas log.
  String _redactedBody(Map<String, dynamic>? body) {
    if (body == null || body.isEmpty) return '';

    const secretKeys = {'password', 'password_confirmation', 'token'};
    final safe = {
      for (final entry in body.entries)
        entry.key: secretKeys.contains(entry.key.toLowerCase())
            ? '***'
            : entry.value,
    };
    return jsonEncode(safe);
  }

  Uri _uriFor(String path) => Uri.parse('${ApiConfig.baseUrl}$path');

  Map<String, String> _headers({required bool authenticated}) {
    final header = _authorizationHeader;
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (authenticated && header != null) 'Authorization': header,
    };
  }

  /// Menjalankan request lalu menerjemahkan setiap cara gagalnya menjadi
  /// [ApiException].
  Future<dynamic> _send(
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

    return _unwrap(response);
  }

  static String _truncate(String body, [int max = 500]) =>
      body.length <= max ? body : '${body.substring(0, max)}…';

  /// Membuka amplop respons, atau melempar [ApiException] yang sesuai.
  ///
  /// Mengembalikan isi `data` apa adanya (bisa Map, bisa List) — pemanggil
  /// ([_expectMap] / [_expectList]) yang menentukan bentuk mana yang
  /// diharapkan untuk endpoint tersebut.
  dynamic _unwrap(http.Response response) {
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
    if (envelope.containsKey('status') && envelope['status'] != 'success') {
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

    return envelope['data'];
  }

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
