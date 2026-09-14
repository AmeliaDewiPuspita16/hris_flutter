import 'package:flutter/widgets.dart';

import '../../domain/login_credentials.dart';

/// Menyimpan seluruh state form login, terpisah dari widget-nya.
///
/// Memakai [ChangeNotifier] bawaan Flutter supaya tidak perlu menambah
/// package state management ke project.
class LoginFormController extends ChangeNotifier {
  final employeeNumberController = TextEditingController();
  final passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _keepSignedIn = true;
  bool _submitted = false;

  bool get obscurePassword => _obscurePassword;
  bool get keepSignedIn => _keepSignedIn;

  LoginCredentials get credentials => LoginCredentials(
        employeeNumber: employeeNumberController.text.trim(),
        password: passwordController.text,
      );

  /// Error baru muncul setelah tombol Sign in ditekan, supaya form tidak
  /// langsung merah begitu halaman dibuka.
  String? get employeeNumberError =>
      _submitted ? credentials.employeeNumberError : null;

  String? get passwordError => _submitted ? credentials.passwordError : null;

  void togglePasswordVisibility() {
    _obscurePassword = !_obscurePassword;
    notifyListeners();
  }

  void toggleKeepSignedIn() {
    _keepSignedIn = !_keepSignedIn;
    notifyListeners();
  }

  /// Menandai form sudah disubmit, lalu melaporkan apakah input valid.
  bool submit() {
    _submitted = true;
    notifyListeners();
    return credentials.isValid;
  }

  @override
  void dispose() {
    employeeNumberController.dispose();
    passwordController.dispose();
    super.dispose();
  }
}
