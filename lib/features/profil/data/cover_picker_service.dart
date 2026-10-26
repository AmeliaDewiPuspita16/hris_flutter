import 'dart:io';
import 'dart:ui' as ui;

import 'package:image_picker/image_picker.dart';

import '../../../core/logging/app_logger.dart';
import '../domain/photo_pick_exception.dart';
import '../domain/photo_source.dart';

/// Gambar cover yang sudah lolos syarat server, beserta ukurannya (dipakai
/// layar atur posisi).
class PickedCover {
  const PickedCover(
      {required this.file, required this.width, required this.height});

  final File file;
  final int width;
  final int height;
}

/// Memilih gambar cover dari kamera/galeri lalu memeriksa syarat server:
/// JPG/PNG, maks 6 MB, minimal 800x300 px. Tidak ada layar crop — posisi
/// diatur di layar "Preview & adjust".
class CoverPickerService {
  CoverPickerService({ImagePicker? picker}) : _picker = picker ?? ImagePicker();

  final ImagePicker _picker;

  static const int maxBytes = 6 * 1024 * 1024;
  static const int minWidth = 800;
  static const int minHeight = 300;

  /// Null bila user membatalkan. Melempar [PhotoPickException] bila gambar
  /// tidak memenuhi syarat atau kamera/galeri tidak bisa dibuka.
  Future<PickedCover?> pick(PhotoSource source) async {
    final XFile? picked;
    try {
      picked = await _picker.pickImage(
        source: source == PhotoSource.camera
            ? ImageSource.camera
            : ImageSource.gallery,
        // Mengecilkan foto kamera beresolusi tinggi supaya di bawah 6 MB,
        // dan memaksa encode ulang ke JPEG (foto HEIC iPhone ditolak server).
        maxWidth: 2400,
        maxHeight: 2400,
        imageQuality: 88,
      );
    } catch (e, stack) {
      AppLogger.error('Gagal membuka kamera/galeri untuk cover', e, stack);
      throw const PhotoPickException(
          'Unable to open the camera/gallery. Please check the app permissions.');
    }
    if (picked == null) return null;

    var file = File(picked.path);
    final bytes = await file.readAsBytes();

    final ext = _detectExtension(bytes);
    if (ext == null) {
      throw const PhotoPickException('The cover must be a JPG or PNG image.');
    }
    if (bytes.length > maxBytes) {
      throw const PhotoPickException('The image is too large (max 6 MB).');
    }

    final ui.Image image;
    try {
      final codec = await ui.instantiateImageCodec(bytes);
      image = (await codec.getNextFrame()).image;
    } catch (e, stack) {
      AppLogger.error('Gagal membaca gambar cover', e, stack);
      throw const PhotoPickException('The image could not be read.');
    }
    final width = image.width;
    final height = image.height;
    image.dispose();

    if (width < minWidth || height < minHeight) {
      throw const PhotoPickException(
          'The cover must be at least $minWidth x $minHeight pixels.');
    }

    // Nama berkas disamakan dengan isinya supaya Content-Type yang dikirim
    // ke server benar (path image_picker bisa tanpa ekstensi).
    final lower = file.path.toLowerCase();
    final nameOk =
        lower.endsWith('.$ext') || (ext == 'jpg' && lower.endsWith('.jpeg'));
    if (!nameOk) {
      file = await file.copy(
        '${Directory.systemTemp.path}/cover_${DateTime.now().millisecondsSinceEpoch}.$ext',
      );
    }
    return PickedCover(file: file, width: width, height: height);
  }

  /// `jpg`/`png` dari beberapa byte pertama, null untuk format lain.
  static String? _detectExtension(List<int> head) {
    if (head.length >= 3 &&
        head[0] == 0xFF &&
        head[1] == 0xD8 &&
        head[2] == 0xFF) {
      return 'jpg';
    }
    if (head.length >= 4 &&
        head[0] == 0x89 &&
        head[1] == 0x50 &&
        head[2] == 0x4E &&
        head[3] == 0x47) {
      return 'png';
    }
    return null;
  }
}
