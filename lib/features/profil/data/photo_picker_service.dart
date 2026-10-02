import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/logging/app_logger.dart';
import '../../../core/theme/app_colors.dart';
import '../domain/photo_pick_exception.dart';
import '../domain/photo_source.dart';

/// Semua urusan yang menyentuh perangkat untuk foto profil: membuka
/// kamera/galeri, layar crop, lalu memeriksa syarat server (JPG/PNG, maks
/// 1 MB). Tidak tahu soal HTTP — itu urusan `ProfilRepository`.
class PhotoPickerService {
  PhotoPickerService({ImagePicker? picker, ImageCropper? cropper})
      : _picker = picker ?? ImagePicker(),
        _cropper = cropper ?? ImageCropper();

  final ImagePicker _picker;
  final ImageCropper _cropper;

  /// Batas dari server: jpeg/jpg/png, maksimal 1024 KB.
  static const int maxPhotoBytes = 1024 * 1024;

  /// Memilih foto, meng-crop 1:1, lalu memeriksanya.
  ///
  /// Mengembalikan berkas yang siap diunggah, atau null bila user
  /// membatalkan (di pemilih maupun di layar crop).
  ///
  /// Melempar [PhotoPickException] bila foto tidak memenuhi syarat atau
  /// kamera/galeri/crop tidak bisa dibuka.
  Future<File?> pick(PhotoSource source) async {
    final XFile? picked;
    try {
      picked = await _picker.pickImage(
        source: source == PhotoSource.camera ? ImageSource.camera : ImageSource.gallery,
      );
    } catch (e, stack) {
      AppLogger.error('Gagal membuka kamera/galeri', e, stack);
      throw const PhotoPickException('Tidak bisa membuka kamera/galeri. Cek izin aplikasi.');
    }
    if (picked == null) return null;

    final croppedPath = await _cropSquare(picked.path);
    if (croppedPath == null) return null;

    var file = File(croppedPath);

    // Format dibaca dari ISI berkas, bukan namanya: path hasil image_picker
    // bisa tanpa ekstensi, dan path Android memuat titik di nama package.
    final ext = await _detectExtension(file);
    if (ext == null) {
      throw const PhotoPickException('Format foto harus JPG atau PNG.');
    }
    if (await file.length() > maxPhotoBytes) {
      throw const PhotoPickException('Ukuran foto terlalu besar (maksimal 1 MB).');
    }

    // Nama berkas disamakan dengan isinya supaya Content-Type yang dikirim
    // ke server benar.
    final lower = file.path.toLowerCase();
    final nameOk = lower.endsWith('.$ext') || (ext == 'jpg' && lower.endsWith('.jpeg'));
    if (!nameOk) {
      file = await file.copy(
        '${Directory.systemTemp.path}/avatar_${DateTime.now().millisecondsSinceEpoch}.$ext',
      );
    }
    return file;
  }

  /// Layar crop bawaan platform: bingkai bulat, rasio 1:1 terkunci, hasil
  /// JPG 800x800. Null bila user membatalkan.
  Future<String?> _cropSquare(String sourcePath) async {
    try {
      final cropped = await _cropper.cropImage(
        sourcePath: sourcePath,
        aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
        compressFormat: ImageCompressFormat.jpg,
        compressQuality: 85,
        maxWidth: 800,
        maxHeight: 800,
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Atur foto profil',
            toolbarColor: AppColors.primary,
            toolbarWidgetColor: Colors.white,
            activeControlsWidgetColor: AppColors.primary,
            initAspectRatio: CropAspectRatioPreset.square,
            lockAspectRatio: true,
            cropStyle: CropStyle.circle,
          ),
          IOSUiSettings(
            title: 'Atur foto profil',
            aspectRatioLockEnabled: true,
            aspectRatioPickerButtonHidden: true,
            resetAspectRatioEnabled: false,
            cropStyle: CropStyle.circle,
          ),
        ],
      );
      return cropped?.path;
    } catch (e, stack) {
      // Penyebab aslinya (mis. plugin belum terdaftar, UCropActivity belum
      // ada di manifest) hanya terlihat di log, jadi jangan dibuang.
      AppLogger.error('Gagal membuka layar crop foto', e, stack);
      throw const PhotoPickException('Gagal membuka layar crop foto.');
    }
  }

  /// Mengenali format dari beberapa byte pertama berkas: `jpg` untuk JPEG,
  /// `png` untuk PNG, null untuk selain itu (mis. HEIC, WebP, bukan gambar).
  Future<String?> _detectExtension(File file) async {
    final raf = await file.open();
    try {
      final head = await raf.read(8);
      if (head.length >= 3 && head[0] == 0xFF && head[1] == 0xD8 && head[2] == 0xFF) {
        return 'jpg';
      }
      if (head.length >= 8 &&
          head[0] == 0x89 &&
          head[1] == 0x50 &&
          head[2] == 0x4E &&
          head[3] == 0x47) {
        return 'png';
      }
      return null;
    } finally {
      await raf.close();
    }
  }
}
