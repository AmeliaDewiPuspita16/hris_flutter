/// Hal-hal yang bisa terjadi pada form login.
sealed class LoginEvent {
  const LoginEvent();
}

/// Pengguna menekan tombol Sign in dengan input yang sudah lolos validasi
/// lokal.
class LoginSubmitted extends LoginEvent {
  const LoginSubmitted({required this.email, required this.password});

  final String email;
  final String password;
}

/// Mengembalikan form ke keadaan awal, misalnya setelah pesan galat dibaca.
class LoginReset extends LoginEvent {
  const LoginReset();
}
