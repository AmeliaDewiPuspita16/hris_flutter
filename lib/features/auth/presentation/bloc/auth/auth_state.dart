import '../../../domain/auth_session.dart';

enum AuthStatus {
  /// Sesi tersimpan belum selesai diperiksa — layar splash yang tampil.
  unknown,
  authenticated,
  unauthenticated,
}

/// Status sesi aplikasi. Satu-satunya yang menentukan layar mana yang tampil.
class AuthState {
  const AuthState._(this.status, this.session);

  const AuthState.unknown() : this._(AuthStatus.unknown, null);

  const AuthState.unauthenticated() : this._(AuthStatus.unauthenticated, null);

  const AuthState.authenticated(AuthSession session)
      : this._(AuthStatus.authenticated, session);

  final AuthStatus status;

  /// Terisi hanya saat [status] bernilai [AuthStatus.authenticated].
  final AuthSession? session;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AuthState &&
          other.status == status &&
          identical(other.session, session);

  @override
  int get hashCode => Object.hash(status, session);

  @override
  String toString() => 'AuthState(${status.name})';
}
