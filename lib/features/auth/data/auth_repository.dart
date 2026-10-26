import 'dart:async';

import '../../../core/logging/app_logger.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_config.dart';
import '../../../core/network/api_exception.dart';
import '../../notifikasi/data/device_token_repository.dart';
import '../domain/auth_session.dart';
import 'session_storage.dart';

/// Pintu masuk fitur auth: tahu soal login dan sesi, tidak tahu soal HTTP.
class AuthRepository {
  AuthRepository({
    required ApiClient apiClient,
    required SessionStorage storage,
    DeviceTokenRepository? deviceTokens,
    Future<String?> Function()? fcmToken,
    Stream<String>? fcmTokenRefreshes,
  })  : _apiClient = apiClient,
        _storage = storage,
        _deviceTokens = deviceTokens,
        _fcmToken = fcmToken {
    // FCM bisa merotasi token kapan saja (reinstall, clear data). Yang baru
    // didaftarkan ulang hanya kalau ada sesi — tanpa sesi, server tidak tahu
    // token itu milik siapa.
    fcmTokenRefreshes?.listen((token) {
      if (_apiClient.authorizationHeader != null) {
        unawaited(_registerDevice(token));
      }
    });
  }

  final ApiClient _apiClient;
  final SessionStorage _storage;

  /// Pendaftaran push notification. Keduanya null (mis. di test) berarti
  /// push dimatikan — login/logout tetap berjalan seperti biasa.
  final DeviceTokenRepository? _deviceTokens;
  final Future<String?> Function()? _fcmToken;

  /// Token yang terakhir berhasil didaftarkan, supaya logout mencabut token
  /// yang memang tercatat di server.
  String? _registeredToken;

  /// Menukar kredensial dengan sesi baru, menyimpannya, lalu memasang
  /// token-nya ke [ApiClient].
  ///
  /// [fcmToken] dikirim bareng kredensial supaya backend bisa mengaitkan
  /// device token push notification ini dengan user yang baru login. Null
  /// kalau Firebase Messaging belum siap/gagal ambil token — login tetap
  /// jalan seperti biasa, hanya saja push notification belum aktif untuk
  /// device ini sampai token berhasil didapat (mis. setelah restart app).
  Future<AuthSession> login({
    required String email,
    required String password,
    String? fcmToken,
  }) async {
    final Map<String, dynamic> data;
    try {
      data = await _apiClient.post(
        ApiConfig.login,
        body: {
          'email': email,
          'password': password,
          if (fcmToken != null) 'fcm_token': fcmToken,
        },
        // Token lama tidak relevan di sini, dan bisa saja sudah kedaluwarsa.
        authenticated: false,
      );
    } on ApiException catch (e) {
      // Saat login, 401 berarti kredensialnya salah — bukan sesi berakhir.
      if (e.kind == ApiErrorKind.unauthorized) {
        throw const ApiException(
          ApiErrorKind.unauthorized,
          'Incorrect email or password.',
        );
      }
      rethrow;
    }

    final AuthSession session;
    try {
      session = AuthSession.fromJson(data);
    } on FormatException {
      throw const ApiException.server(
        'Unrecognized login response. Please contact the IT team.',
      );
    }

    await _storage.write(session);
    _apiClient.setToken(session.token, tokenType: session.tokenType);

    // Tidak di-await: login tidak boleh menunggu, apalagi gagal, hanya
    // karena pendaftaran push bermasalah.
    if (fcmToken != null) unawaited(_registerDevice(fcmToken));
    return session;
  }

  /// Menyimpan [session] sebagai sesi tersimpan, mis. setelah data user di
  /// dalamnya diperbarui. Token tidak dipasang ulang ke [ApiClient] karena
  /// pemanggil tidak mengubahnya.
  Future<void> saveSession(AuthSession session) => _storage.write(session);

  /// Sesi dari peluncuran sebelumnya, atau null bila tidak ada.
  Future<AuthSession?> restoreSession() async {
    final session = await _storage.read();
    if (session == null) return null;

    _apiClient.setToken(session.token, tokenType: session.tokenType);

    // Didaftarkan ulang tiap app dibuka: token bisa saja berganti selagi app
    // tertutup, dan sesi lama (sebelum fitur push ada) belum pernah
    // mendaftarkan token sama sekali.
    unawaited(_registerCurrentDevice());
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
      // Sebelum token sesi dicabut: endpoint-nya butuh Authorization. Tanpa
      // ini HP tetap menerima push milik akun yang sudah keluar.
      await _unregisterDevice();

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

  Future<void> _registerCurrentDevice() async {
    final provider = _fcmToken;
    if (provider == null || _deviceTokens == null) return;

    final token = await provider();
    if (token != null) await _registerDevice(token);
  }

  Future<void> _registerDevice(String token) async {
    final deviceTokens = _deviceTokens;
    if (deviceTokens == null) return;

    try {
      await deviceTokens.register(token);
      _registeredToken = token;
    } catch (e, stack) {
      AppLogger.error('Gagal mendaftarkan FCM token ke server', e, stack);
    }
  }

  Future<void> _unregisterDevice() async {
    final deviceTokens = _deviceTokens;
    if (deviceTokens == null) return;

    final token = _registeredToken ?? await _fcmToken?.call();
    if (token == null) return;

    try {
      await deviceTokens.unregister(token);
    } catch (e, stack) {
      AppLogger.error('Gagal mencabut FCM token di server', e, stack);
    } finally {
      _registeredToken = null;
    }
  }
}
