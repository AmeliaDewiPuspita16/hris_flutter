import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

import '../../../../../../core/theme/app_colors.dart';
import '../../../../../../core/theme/app_text_styles.dart';

/// Foto bukti pembacaan, atau keterangan singkat bila tidak ada.
///
/// Alamat berawalan `http` dimuat dari jaringan; selain itu dianggap path
/// berkas di perangkat (itulah yang terjadi pada data dummy, tempat foto
/// hasil pilihan petugas disimpan apa adanya).
class MeterPhotoGrid extends StatelessWidget {
  const MeterPhotoGrid({super.key, required this.photos});

  final List<String> photos;

  @override
  Widget build(BuildContext context) {
    if (photos.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 22),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.photo_camera_outlined, size: 18, color: AppColors.textMuted),
            const SizedBox(width: 8),
            Text('No photo uploaded for this reading.', style: AppTextStyles.bodyMuted),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [for (final photo in photos) _Thumb(source: photo)],
      ),
    );
  }
}

class _Thumb extends StatelessWidget {
  const _Thumb({required this.source});

  final String source;

  Widget _fallback() => Container(
        color: AppColors.neutralBg,
        child: Icon(Icons.broken_image_outlined, color: AppColors.textMuted),
      );

  @override
  Widget build(BuildContext context) {
    final image = kIsWeb || source.startsWith('http') || source.startsWith('blob:')
        ? Image.network(
            source,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _fallback(),
          )
        : Image.file(
            File(source),
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _fallback(),
          );

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(width: 96, height: 96, child: image),
    );
  }
}
