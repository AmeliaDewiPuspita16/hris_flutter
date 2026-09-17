/// Satu foto yang dilampirkan ke pengumuman.
///
/// Sengaja tidak memakai tipe dari image_picker supaya aturan validasinya
/// bisa diuji tanpa plugin dan tanpa menyentuh berkas sungguhan.
class AnnouncementPhoto {
  const AnnouncementPhoto({
    required this.path,
    required this.fileName,
    required this.sizeBytes,
  });

  final String path;
  final String fileName;
  final int sizeBytes;

  /// Batas dari dokumentasi `POST /api/portal/hr_announcement`.
  static const int maxCount = 10;
  static const int maxSizeBytes = 5 * 1024 * 1024;
  static const Set<String> allowedExtensions = {'jpeg', 'jpg', 'png'};

  /// Ekstensi berkas dalam huruf kecil, tanpa titik. Kosong bila tidak ada.
  String get extension {
    final dot = fileName.lastIndexOf('.');
    if (dot < 0 || dot == fileName.length - 1) return '';
    return fileName.substring(dot + 1).toLowerCase();
  }

  /// Alasan foto ini ditolak, atau null bila memenuhi syarat.
  ///
  /// Pesannya berbahasa Indonesia dan menyebut nama berkas, supaya pengguna
  /// tahu foto mana yang harus diganti tanpa menebak.
  String? get validationError {
    if (!allowedExtensions.contains(extension)) {
      return '$fileName bukan JPG atau PNG.';
    }
    if (sizeBytes <= 0) {
      return '$fileName kosong atau tidak bisa dibaca.';
    }
    if (sizeBytes > maxSizeBytes) {
      return '$fileName lebih dari 5 MB.';
    }
    return null;
  }

  /// Alasan sekumpulan foto ditolak, atau null bila semuanya memenuhi syarat.
  static String? errorForSelection(List<AnnouncementPhoto> photos) {
    if (photos.length > maxCount) {
      return 'Maksimal $maxCount foto per pengumuman.';
    }
    for (final photo in photos) {
      final error = photo.validationError;
      if (error != null) return error;
    }
    return null;
  }
}
