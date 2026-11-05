import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../../../core/theme/app_colors.dart';
import '../../../../../../core/theme/app_text_styles.dart';
import '../../../../../../core/widgets/field_label_row.dart';

/// Isian satu foto opsional (png / jpg / jpeg, maks 2 MB) — aturan sama
/// dengan kolom "Image" di form Add & Close web. Foto yang tidak memenuhi
/// aturan ditolak lewat [onError] (pesan siap tampil), bukan diterima.
class ObservationImageField extends StatelessWidget {
  const ObservationImageField({
    super.key,
    required this.label,
    required this.path,
    required this.onChanged,
    required this.onError,
  });

  final String label;

  /// Path file terpilih, null = belum ada.
  final String? path;
  final ValueChanged<String?> onChanged;
  final ValueChanged<String> onError;

  static const _allowed = ['png', 'jpg', 'jpeg'];
  static const _maxBytes = 2 * 1024 * 1024;

  Future<void> _pick(BuildContext context) async {
    final source = await showModalBottomSheet<ImageSource>(
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
              _SourceOption(
                icon: Icons.camera_alt_outlined,
                label: 'Camera',
                onTap: () => Navigator.pop(ctx, ImageSource.camera),
              ),
              _SourceOption(
                icon: Icons.photo_library_outlined,
                label: 'Gallery',
                onTap: () => Navigator.pop(ctx, ImageSource.gallery),
              ),
            ],
          ),
        ),
      ),
    );
    if (source == null) return;

    final picked = await ImagePicker().pickImage(
      source: source,
      imageQuality: 80,
      maxWidth: 1920,
    );
    if (picked == null) return;

    final ext = picked.path.split('.').last.toLowerCase();
    if (!_allowed.contains(ext)) {
      onError('Image must be a PNG, JPG, or JPEG file.');
      return;
    }
    if (await File(picked.path).length() > _maxBytes) {
      onError('Image must not exceed 2 MB.');
      return;
    }
    onChanged(picked.path);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FieldLabelRow(label: label),
        if (path == null)
          InkWell(
            onTap: () => _pick(context),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              height: 92,
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.presentBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.primaryText.withValues(alpha: 0.35),
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_photo_alternate_outlined,
                      size: 26, color: AppColors.primaryText),
                  const SizedBox(height: 6),
                  Text(
                    'Add photo',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.primaryText,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text('PNG / JPG / JPEG — max 2 MB',
                      style: AppTextStyles.caption.copyWith(fontSize: 10.5)),
                ],
              ),
            ),
          )
        else
          Stack(
            clipBehavior: Clip.none,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(
                  File(path!),
                  height: 160,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
              Positioned(
                top: -8,
                right: -8,
                child: GestureDetector(
                  onTap: () => onChanged(null),
                  child: Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      color: AppColors.solid(AppColors.rejected),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.close, color: Colors.white, size: 16),
                  ),
                ),
              ),
            ],
          ),
      ],
    );
  }
}

class _SourceOption extends StatelessWidget {
  const _SourceOption({
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
