import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../domain/auth_session.dart';

/// Tempat sesi login bertahan antar-peluncuran aplikasi.
abstract class SessionStorage {
  /// Sesi tersimpan, atau null bila belum pernah login.
  Future<AuthSession?> read();

  Future<void> write(AuthSession session);

  Future<void> clear();
}

/// Menyimpan sesi terenkripsi di Keychain (iOS) / EncryptedSharedPreferences
/// (Android).
///
/// Seluruh sesi ikut disimpan, bukan token saja, karena API tidak menyediakan
/// endpoint untuk mengambil ulang data pengguna dari sebuah token.
class SecureSessionStorage implements SessionStorage {
  SecureSessionStorage({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  static const String _key = 'auth_session';

  final FlutterSecureStorage _storage;

  /// Sesi yang tidak bisa dibaca dianggap tidak ada — pengguna cukup diminta
  /// login ulang, jauh lebih baik daripada aplikasi gagal terbuka.
  @override
  Future<AuthSession?> read() async {
    final raw = await _storage.read(key: _key);
    if (raw == null || raw.isEmpty) return null;

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return null;
      return AuthSession.fromJson(decoded);
    } on FormatException {
      return null;
    }
  }

  @override
  Future<void> write(AuthSession session) {
    return _storage.write(key: _key, value: jsonEncode(session.toJson()));
  }

  @override
  Future<void> clear() => _storage.delete(key: _key);
}
