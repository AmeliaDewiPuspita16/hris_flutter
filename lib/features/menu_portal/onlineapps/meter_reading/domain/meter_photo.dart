/// Dari mana foto bukti diambil.
enum MeterPhotoSource { camera, gallery }

/// Membuka kamera atau galeri dan mengembalikan foto yang dihasilkan, atau
/// null bila dibatalkan.
///
/// Disuntik lewat konstruktor supaya test bisa menggantinya tanpa plugin
/// sungguhan — pola sama dengan `AttachmentPicker` di modul it_request.
typedef MeterPhotoPicker = Future<MeterPhoto?> Function(MeterPhotoSource source);

/// Satu foto bukti pembacaan meter.
///
/// Sengaja tidak memakai tipe dari image_picker, supaya aturan validasinya
/// bisa diuji tanpa plugin dan tanpa menyentuh berkas sungguhan.
class MeterPhoto {
  const MeterPhoto({
    required this.path,
    required this.fileName,
    required this.sizeBytes,
  });

  final String path;
  final String fileName;
  final int sizeBytes;

  // Batas dan ekstensi di bawah ini meminjam aturan lampiran IT Request —
  // belum ada ketentuan dari server untuk Meter Reading. Sesuaikan saat
  // kontrak API dibuat.
  static const int maxSizeBytes = 10 * 1024 * 1024;
  static const Set<String> allowedExtensions = {'jpg', 'jpeg', 'png', 'gif', 'webp'};

  /// Ekstensi berkas dalam huruf kecil, tanpa titik. Kosong bila tidak ada.
  String get extension {
    final dot = fileName.lastIndexOf('.');
    if (dot < 0 || dot == fileName.length - 1) return '';
    return fileName.substring(dot + 1).toLowerCase();
  }

  /// Alasan foto ini ditolak, atau null bila memenuhi syarat.
  String? get validationError {
    if (!allowedExtensions.contains(extension)) {
      return '$fileName must be a JPG, JPEG, PNG, GIF, or WEBP file.';
    }
    if (sizeBytes <= 0) return '$fileName is empty or cannot be read.';
    if (sizeBytes > maxSizeBytes) return '$fileName is larger than 10 MB.';
    return null;
  }
}
