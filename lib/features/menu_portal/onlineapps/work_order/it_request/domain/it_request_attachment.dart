/// Satu berkas gambar yang dilampirkan ke sebuah IT/Media Request.
///
/// Sengaja tidak memakai tipe dari image_picker supaya aturan validasinya
/// bisa diuji tanpa plugin dan tanpa menyentuh berkas sungguhan — pola sama
/// dengan `AnnouncementPhoto` di form pengumuman. Aturannya sendiri beda
/// (ekstensi dan batas ukuran mengikuti dokumentasi
/// `POST /api/portal/apps/it_request`, bukan endpoint pengumuman), jadi
/// dibuat model terpisah alih-alih dipaksa berbagi dengan `AnnouncementPhoto`.
class ItRequestAttachment {
  const ItRequestAttachment({
    required this.path,
    required this.fileName,
    required this.sizeBytes,
  });

  final String path;
  final String fileName;
  final int sizeBytes;

  static const int maxSizeBytes = 10 * 1024 * 1024;
  static const Set<String> allowedExtensions = {'jpg', 'jpeg', 'png', 'gif', 'webp'};

  /// Ekstensi berkas dalam huruf kecil, tanpa titik. Kosong bila tidak ada.
  String get extension {
    final dot = fileName.lastIndexOf('.');
    if (dot < 0 || dot == fileName.length - 1) return '';
    return fileName.substring(dot + 1).toLowerCase();
  }

  /// Alasan berkas ini ditolak, atau null bila memenuhi syarat.
  ///
  /// Pesannya menyebut nama berkas supaya pengguna tahu mana yang harus
  /// diganti tanpa perlu menebak — cuma satu lampiran per request, tapi
  /// pesan yang jelas tetap lebih baik daripada "berkas tidak valid".
  String? get validationError {
    if (!allowedExtensions.contains(extension)) {
      return '$fileName harus JPG, JPEG, PNG, GIF, atau WEBP.';
    }
    if (sizeBytes <= 0) {
      return '$fileName kosong atau tidak bisa dibaca.';
    }
    if (sizeBytes > maxSizeBytes) {
      return '$fileName lebih dari 10 MB.';
    }
    return null;
  }
}
