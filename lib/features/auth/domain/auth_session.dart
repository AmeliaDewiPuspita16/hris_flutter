import 'auth_user.dart';

/// Sesi yang sedang aktif: token akses beserta pemiliknya.
class AuthSession {
  const AuthSession({
    required this.token,
    required this.user,
    this.tokenType = 'Bearer',
  });

  final String token;

  /// Diambil dari `token_type` respons login, dipakai apa adanya saat
  /// menyusun header Authorization.
  final String tokenType;

  final AuthUser user;

  /// Kebalikan dari [fromJson], bentuknya sama dengan objek `data` milik
  /// server sehingga bisa dibaca ulang oleh [fromJson].
  Map<String, dynamic> toJson() {
    return {
      'access_token': token,
      'token_type': tokenType,
      'user': user.toJson(),
    };
  }

  /// Memetakan objek `data` dari respons login.
  ///
  /// Melempar [FormatException] bila token atau user tidak ada — tanpa
  /// keduanya sesi tidak berarti apa-apa, dan lebih baik gagal keras di sini
  /// daripada menyimpan sesi cacat.
  factory AuthSession.fromJson(Map<String, dynamic> json) {
    final token = json['access_token'];
    if (token is! String || token.isEmpty) {
      throw const FormatException('Respons login tidak memuat access_token');
    }

    final user = json['user'];
    if (user is! Map<String, dynamic>) {
      throw const FormatException('Respons login tidak memuat data user');
    }

    final tokenType = json['token_type'];

    return AuthSession(
      token: token,
      tokenType: tokenType is String && tokenType.isNotEmpty
          ? tokenType
          : 'Bearer',
      user: AuthUser.fromJson(user),
    );
  }
}
