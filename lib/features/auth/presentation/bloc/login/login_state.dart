import '../../../domain/auth_session.dart';

enum LoginStatus { initial, loading, success, failure }

/// Keadaan form login.
class LoginState {
  const LoginState({
    this.status = LoginStatus.initial,
    this.errorMessage,
    this.session,
  });

  final LoginStatus status;

  /// Pesan galat dari server, sudah siap ditampilkan.
  final String? errorMessage;

  /// Terisi hanya saat [status] bernilai [LoginStatus.success].
  final AuthSession? session;

  bool get isLoading => status == LoginStatus.loading;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LoginState &&
          other.status == status &&
          other.errorMessage == errorMessage &&
          identical(other.session, session);

  @override
  int get hashCode => Object.hash(status, errorMessage, session);

  @override
  String toString() => 'LoginState(${status.name}, error: $errorMessage)';
}
