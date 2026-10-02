import 'dart:io';

import '../../../../auth/domain/auth_user.dart';

enum ProfilPhotoStatus { initial, picking, uploading, success, failure }

/// Keadaan foto profil di layar Profil.
class ProfilPhotoState {
  const ProfilPhotoState({
    this.status = ProfilPhotoStatus.initial,
    this.photo,
    this.user,
    this.errorMessage,
  });

  final ProfilPhotoStatus status;

  /// Foto yang baru dipilih, ditampilkan langsung tanpa menunggu foto dari
  /// server selesai dimuat. Null berarti pakai foto/inisial dari user.
  final File? photo;

  /// Terisi hanya saat [status] `success`: user terbaru dari server, untuk
  /// diteruskan ke `AuthBloc`.
  final AuthUser? user;

  final String? errorMessage;

  /// True selama kamera/galeri/crop terbuka atau upload berjalan; layar
  /// memakainya untuk mengabaikan ketukan ganda.
  bool get isBusy =>
      status == ProfilPhotoStatus.picking || status == ProfilPhotoStatus.uploading;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProfilPhotoState &&
          other.status == status &&
          other.photo?.path == photo?.path &&
          identical(other.user, user) &&
          other.errorMessage == errorMessage;

  @override
  int get hashCode => Object.hash(status, photo?.path, user, errorMessage);

  @override
  String toString() => 'ProfilPhotoState(${status.name}, error: $errorMessage)';
}
