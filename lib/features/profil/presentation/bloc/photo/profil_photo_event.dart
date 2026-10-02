import '../../../domain/photo_source.dart';

/// Hal-hal yang bisa terjadi pada foto profil.
sealed class ProfilPhotoEvent {
  const ProfilPhotoEvent();
}

/// User memilih asal foto di bottom sheet. Bloc yang melanjutkan: membuka
/// kamera/galeri, crop, lalu mengunggah hasilnya.
class ProfilPhotoPickRequested extends ProfilPhotoEvent {
  const ProfilPhotoPickRequested(this.source);

  final PhotoSource source;
}
