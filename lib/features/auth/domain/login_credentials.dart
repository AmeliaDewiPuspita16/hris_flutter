/// Kredensial login beserta aturan validasinya.
///
/// Murni Dart — tidak menyentuh Flutter sama sekali, jadi aturan bisnisnya
/// bisa diuji tanpa perlu me-render widget.
class LoginCredentials {
  const LoginCredentials({
    required this.employeeNumber,
    required this.password,
  });

  final String employeeNumber;
  final String password;

  static const minPasswordLength = 8;

  /// NIK BIIE: dua digit tahun masuk, tanda hubung, empat digit urut.
  /// Contoh: 20-4471.
  static final _nikPattern = RegExp(r'^\d{2}-\d{4}$');

  String? get employeeNumberError {
    if (employeeNumber.isEmpty) return 'Nomor induk karyawan wajib diisi';
    if (!_nikPattern.hasMatch(employeeNumber)) {
      return 'Format NIK tidak sesuai, contoh: 20-4471';
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

  bool get isValid => employeeNumberError == null && passwordError == null;
}
