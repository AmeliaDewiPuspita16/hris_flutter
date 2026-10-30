import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../../../core/theme/app_colors.dart';

/// Pilihan sumber foto: kamera atau galeri (bisa pilih banyak). Hasil null =
/// ditutup tanpa memilih. Galeri dikembalikan sebagai [ImageSource.gallery].
class EstPhotoSourceSheet {
  const EstPhotoSourceSheet._();

  static Future<ImageSource?> show(BuildContext context) {
    return showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _Option(
                icon: Icons.camera_alt_outlined,
                label: 'Kamera',
                onTap: () => Navigator.pop(ctx, ImageSource.camera),
              ),
              _Option(
                icon: Icons.photo_library_outlined,
                label: 'Galeri (bisa pilih banyak)',
                onTap: () => Navigator.pop(ctx, ImageSource.gallery),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Option extends StatelessWidget {
  const _Option({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.presentBg,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: AppColors.primaryText, size: 20),
      ),
      title: Text(
        label,
        style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.text),
      ),
      onTap: onTap,
    );
  }
}
