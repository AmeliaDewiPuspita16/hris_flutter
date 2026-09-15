import '../../../core/logging/app_logger.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_config.dart';
import '../../../core/network/api_exception.dart';
import '../domain/auth_session.dart';
import 'session_storage.dart';

/// Pintu masuk fitur auth: tahu soal login dan sesi, tidak tahu soal HTTP.
class AuthRepository {
  AuthRepository({
    required ApiClient apiClient,
    required SessionStorage storage,
  })  : _apiClient = apiClient,
        _storage = storage;

  final ApiClient _apiClient;
  final SessionStorage _storage;

  /// Menukar kredensial dengan sesi baru, menyimpannya, lalu memasang
  /// token-nya ke [ApiClient].
  Future<AuthSession> login({
    required String email,
    required String password,
  }) async {
    final Map<String, dynamic> data;
    try {
      data = await _apiClient.post(
        ApiConfig.login,
        body: {'email': email, 'password': password},
        // Token lama tidak relevan di sini, dan bisa saja sudah kedaluwarsa.
        authenticated: false,
      );
    } on ApiException catch (e) {
      // Saat login, 401 berarti kredensialnya salah — bukan sesi berakhir.
      if (e.kind == ApiErrorKind.unauthorized) {
        throw const ApiException(
          ApiErrorKind.unauthorized,
          'Email atau kata sandi salah.',
        );
      }
      rethrow;
    }

    final AuthSession session;
    try {
      session = AuthSession.fromJson(data);
    } on FormatException {
      throw const ApiException.server(
        'Respons login tidak dikenali. Hubungi tim IT.',
      );
    }

    await _storage.write(session);
    _apiClient.setToken(session.token, tokenType: session.tokenType);
    return session;
  }

  /// Sesi dari peluncuran sebelumnya, atau null bila tidak ada.
  Future<AuthSession?> restoreSession() async {
    final session = await _storage.read();
    if (session == null) return null;

    _apiClient.setToken(session.token, tokenType: session.tokenType);
    return session;
  }

  /// Mencabut token di server, lalu menghapus sesi tersimpan dan melepas
  /// token dari [ApiClient].
  ///
  /// Pembersihan lokal selalu dijalankan, bahkan ketika permintaan ke server
  /// gagal: pengguna yang sedang offline atau token-nya sudah dicabut tetap
  /// harus bisa keluar dari aplikasi.
  Future<void> logout() async {
    if (_apiClient.authorizationHeader != null) {
      try {
        await _apiClient.post(ApiConfig.logout);
      } on ApiException catch (e) {
        AppLogger.info(
          'Logout di server gagal (${e.message}) — sesi lokal tetap dihapus',
        );
      }
    }

    await _storage.clear();
    _apiClient.setToken(null);
  }
}
