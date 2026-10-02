import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/photo_source.dart';

/// Bottom sheet "Ambil foto / Pilih dari galeri". Mengembalikan pilihan
/// user, atau null bila sheet ditutup tanpa memilih.
Future<PhotoSource?> showPhotoSourceSheet(BuildContext context) {
  return showModalBottomSheet<PhotoSource>(
    context: context,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
    ),
    builder: (ctx) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            _SourceTile(
              icon: Icons.photo_camera_outlined,
              label: 'Ambil foto',
              onTap: () => Navigator.of(ctx).pop(PhotoSource.camera),
            ),
            _SourceTile(
              icon: Icons.photo_library_outlined,
              label: 'Pilih dari galeri',
              onTap: () => Navigator.of(ctx).pop(PhotoSource.gallery),
            ),
          ],
        ),
      ),
    ),
  );
}

class _SourceTile extends StatelessWidget {
  const _SourceTile({required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: AppColors.text, size: 22),
      title: Text(
        label,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.text),
      ),
      onTap: onTap,
    );
  }
}
