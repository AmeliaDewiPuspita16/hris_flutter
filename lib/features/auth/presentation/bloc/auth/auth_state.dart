import '../../../domain/auth_session.dart';

enum AuthStatus {
  /// Sesi tersimpan belum selesai diperiksa — layar splash yang tampil.
  unknown,
  authenticated,
  unauthenticated,
}

/// Status sesi aplikasi. Satu-satunya yang menentukan layar mana yang tampil.
class AuthState {
  const AuthState._(this.status, this.session, {this.sessionExpired = false});

  const AuthState.unknown() : this._(AuthStatus.unknown, null);

  const AuthState.unauthenticated() : this._(AuthStatus.unauthenticated, null);

  /// Keluar paksa karena server menolak token-nya, bukan karena pengguna
  /// menekan Logout — layar login memberi tahu alasannya.
  const AuthState.sessionExpired()
      : this._(AuthStatus.unauthenticated, null, sessionExpired: true);

  const AuthState.authenticated(AuthSession session)
      : this._(AuthStatus.authenticated, session);

  final AuthStatus status;

  /// Terisi hanya saat [status] bernilai [AuthStatus.authenticated].
  final AuthSession? session;

  /// True bila [status] unauthenticated karena sesi kedaluwarsa.
  final bool sessionExpired;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AuthState &&
          other.status == status &&
          other.sessionExpired == sessionExpired &&
          identical(other.session, session);

  @override
  int get hashCode => Object.hash(status, session, sessionExpired);

  @override
  String toString() =>
      'AuthState(${status.name}${sessionExpired ? ', sessionExpired' : ''})';
}
