import '../../../domain/auth_session.dart';
import '../../../domain/auth_user.dart';

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

/// Data user berubah di server (misal. foto profil diganti) - token
/// tetep, hanya [user] pada sesi yang diganti, lalu disimpan.
class AuthUserRefreshed extends AuthEvent {
  const AuthUserRefreshed(this.user);

  final AuthUser user;
}
