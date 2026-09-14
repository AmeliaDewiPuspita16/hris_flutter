/// Kredensial login beserta aturan validasinya.
///
/// Murni Dart — tidak menyentuh Flutter sama sekali, jadi aturan bisnisnya
/// bisa diuji tanpa perlu me-render widget.
class LoginCredentials {
  const LoginCredentials({
    required this.email,
    required this.password,
  });

  final String email;
  final String password;

  static const minPasswordLength = 5;

  /// Pola email sederhana: ada bagian lokal, satu @, domain, dan minimal
  /// satu titik di belakangnya. Validasi sebenarnya tetap milik server.
  static final _emailPattern = RegExp(r'^[\w.+-]+@[\w-]+(\.[\w-]+)+$');

  String? get emailError {
    if (email.isEmpty) return 'Email wajib diisi';
    if (!_emailPattern.hasMatch(email)) {
      return 'Format email tidak sesuai, contoh: nama@biie.co.id';
    }
    return null;
  }

  String? get passwordError {
    if (password.isEmpty) return 'Kata sandi wajib diisi';
    if (password.length < minPasswordLength) {
      return 'Kata sandi minimal $minPasswordLength karakter';
    }
    return null;
  }

  bool get isValid => emailError == null && passwordError == null;
}
