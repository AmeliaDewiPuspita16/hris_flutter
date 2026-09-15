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
    );
  }

  /// Mengirim GET dan mengembalikan isi `data` dari amplop respons.
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
    );
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
  Future<Map<String, dynamic>> _send(
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

    // HTTP 2xx, tapi badan respons masih bisa mengabarkan kegagalan.
    if (envelope == null) throw const ApiException.server();

    if (envelope['status'] != 'success') {
      throw ApiException(
        ApiErrorKind.server,
        serverMessage ?? const ApiException.server().message,
      );
    }

    final data = envelope['data'];
    if (data is! Map<String, dynamic>) throw const ApiException.server();

    return data;
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
