import 'dart:io';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_config.dart';
import '../../../core/network/api_exception.dart';
import '../../auth/domain/auth_user.dart';
import '../domain/profile_cover.dart';

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
        'The photo was uploaded, but the server response was not recognized.',
      );
    }

    try {
      return AuthUser.fromJson(rawUser);
    } on FormatException {
      throw const ApiException.server(
        'The photo was uploaded, but the server response was not recognized.',
      );
    }
  }

  /// Mengganti password user yang sedang login. Token sesi tidak berubah.
  ///
  /// Melempar [ApiException] bila gagal, termasuk galat validasi dari
  /// server (mis. password lama salah) dengan pesan field pertama.
  Future<void> updatePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmation,
  }) {
    return _apiClient.postAction(
      ApiConfig.updatePassword,
      body: {
        'current_password': currentPassword,
        'new_password': newPassword,
        'new_password_confirmation': confirmation,
      },
    );
  }

  /// Cover saat ini beserta pilihan preset-nya.
  Future<ProfileCoverData> fetchCover() async {
    final data = await _apiClient.get(ApiConfig.profileCover);
    final rawPresets = data['presets'];
    return ProfileCoverData(
      cover: ProfileCover.fromJson(data['cover']),
      presets: rawPresets is List
          ? rawPresets.map(CoverPreset.fromJson).whereType<CoverPreset>().toList()
          : const [],
    );
  }

  /// Memasang preset [preset] (gambar upload lama dihapus server).
  Future<ProfileCover> selectCoverPreset(String preset) =>
      _updateCover(fields: {'preset': preset});

  /// Mengunggah [file] sebagai cover dengan posisi [position].
  Future<ProfileCover> uploadCover(File file, CoverPosition position) =>
      _updateCover(
        fields: position.toFields(),
        files: {
          'cover': [file.path],
        },
      );

  /// Hanya mengatur ulang posisi gambar upload yang sudah ada.
  Future<ProfileCover> repositionCover(CoverPosition position) =>
      _updateCover(fields: {'keep': '1', ...position.toFields()});

  Future<ProfileCover> _updateCover({
    required Map<String, String> fields,
    Map<String, List<String>>? files,
  }) async {
    final data = await _apiClient.postMultipart(
      ApiConfig.updateProfileCover,
      fields: fields,
      files: files,
    );
    final cover = ProfileCover.fromJson(data['cover']);
    if (cover == null) {
      throw const ApiException.server(
        'The cover was saved, but the server response was not recognized.',
      );
    }
    return cover;
  }
}
