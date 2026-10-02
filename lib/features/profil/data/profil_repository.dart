import 'dart:io';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_config.dart';
import '../../../core/network/api_exception.dart';
import '../../auth/domain/auth_user.dart';

/// Data profil milik user yang sedang login. Tidak tahu soal HTTP — itu
/// urusan [ApiClient]; tidak tahu soal sesi — itu urusan `AuthBloc`.
class ProfilRepository {
  ProfilRepository({required ApiClient apiClient}) : _apiClient = apiClient;

  final ApiClient _apiClient;

  /// Mengunggah foto profil baru dan mengembalikan [AuthUser] terbaru dari
  /// server (kolom `image` sudah berisi nama berkas baru).
  ///
  /// Respons upload berbentuk sama dengan login (`access_token`,
  /// `token_type`, `user`), tapi hanya `user` yang dipakai: token yang
  /// sedang berlaku tidak berubah.
  ///
  /// Melempar [ApiException] bila gagal, termasuk galat validasi (pesan
  /// dari field yang salah pertama) dan respons yang bentuknya tidak
  /// dikenali.
  Future<AuthUser> uploadPhoto(File file) async {
    final data = await _apiClient.postMultipart(
      ApiConfig.uploadProfile,
      files: {
        'avatar': [file.path],
      },
    );

    final rawUser = data['user'];
    if (rawUser is! Map<String, dynamic>) {
      throw const ApiException.server(
        'Foto terkirim, tapi respons server tidak dikenali.',
      );
    }

    try {
      return AuthUser.fromJson(rawUser);
    } on FormatException {
      throw const ApiException.server(
        'Foto terkirim, tapi respons server tidak dikenali.',
      );
    }
  }
}
