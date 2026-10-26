/// Membuka galeri dan mengembalikan foto yang dipilih, atau null kalau
/// dibatalkan.
///
/// Disuntik lewat konstruktor supaya test bisa menggantinya tanpa plugin
/// galeri sungguhan — pola sama dengan `AttachmentPicker` di IT Request.
typedef EstPhotoPicker = Future<EstRequestPhoto?> Function();

/// Satu foto yang dilampirkan ke Work Order EST.
///
/// Aturannya mengikuti dokumentasi `POST /api/portal/apps/est_work_order`:
/// png/jpg/jpeg, maksimal 2 MB. Sengaja tidak memakai tipe image_picker
/// supaya validasinya bisa diuji tanpa plugin.
class EstRequestPhoto {
  const EstRequestPhoto({
    required this.path,
    required this.fileName,
    required this.sizeBytes,
  });

  final String path;
  final String fileName;
  final int sizeBytes;

  static const int maxSizeBytes = 2 * 1024 * 1024;
  static const Set<String> allowedExtensions = {'jpg', 'jpeg', 'png'};

  /// Ekstensi berkas dalam huruf kecil, tanpa titik. Kosong bila tidak ada.
  String get extension {
    final dot = fileName.lastIndexOf('.');
    if (dot < 0 || dot == fileName.length - 1) return '';
    return fileName.substring(dot + 1).toLowerCase();
  }

  /// Alasan foto ini ditolak, atau null bila memenuhi syarat.
  String? get validationError {
    if (!allowedExtensions.contains(extension)) {
      return 'The image must be a PNG or JPG file.';
    }
    if (sizeBytes <= 0) {
      return '$fileName is empty or cannot be read.';
    }
    if (sizeBytes > maxSizeBytes) {
      return 'The image must not be larger than 2 MB.';
    }
    return null;
  }
}
