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

  // Server: "file gambar, maks. 5 MB" (`image_proof`). Ekstensi yang
  // diizinkan belum dikonfirmasi backend, jadi dibatasi ke yang paling aman.
  static const int maxSizeBytes = 5 * 1024 * 1024;
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
      return '$fileName must be a JPG, JPEG, or PNG file.';
    }
    if (sizeBytes <= 0) return '$fileName is empty or cannot be read.';
    if (sizeBytes > maxSizeBytes) return '$fileName is larger than 5 MB.';
    return null;
  }
}
