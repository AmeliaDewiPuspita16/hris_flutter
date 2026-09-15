import '../../../domain/auth_session.dart';

/// Kejadian yang mengubah status sesi aplikasi.
sealed class AuthEvent {
  const AuthEvent();
}

/// Aplikasi baru dijalankan — periksa apakah ada sesi tersimpan.
class AuthStarted extends AuthEvent {
  const AuthStarted();
}

/// Login berhasil; sesi ini yang berlaku sekarang.
class AuthSessionGranted extends AuthEvent {
  const AuthSessionGranted(this.session);

  final AuthSession session;
}

/// Pengguna menekan Logout.
class AuthLogoutRequested extends AuthEvent {
  const AuthLogoutRequested();
}

/// Server menolak token (401) — sesi dianggap habis.
class AuthSessionExpired extends AuthEvent {
  const AuthSessionExpired();
}
