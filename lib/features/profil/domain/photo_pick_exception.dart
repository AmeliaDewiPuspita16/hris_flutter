/// Foto yang dipilih tidak bisa dipakai (format/ukuran tidak memenuhi syarat,
/// atau kamera/galeri/crop tidak bisa dibuka). [message] aman ditampilkan
/// langsung ke user.
class PhotoPickException implements Exception {
  const PhotoPickException(this.message);

  final String message;

  @override
  String toString() => 'PhotoPickException: $message';
}
