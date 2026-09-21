import 'package:flutter/material.dart';

import '../../../../../../../core/theme/app_colors.dart';
import '../../../../../../../core/theme/app_text_styles.dart';

/// Field foto bergaya dashed-box dengan ikon kamera di tengah, khusus untuk
/// form Add Request EST.
class EstPhotoUploadField extends StatelessWidget {
  const EstPhotoUploadField({
    super.key,
    required this.fileName,
    required this.onTap,
    this.hint = 'Optional · max 2MB',
  });

  final String? fileName;
  final VoidCallback onTap;
  final String hint;

  @override
  Widget build(BuildContext context) {
    final hasFile = fileName != null;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(9),
              ),
              child: Icon(
                hasFile ? Icons.insert_drive_file_outlined : Icons.camera_alt_outlined,
                size: 16,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    hasFile ? fileName! : 'Add photo',
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 1),
                  Text(hasFile ? 'Optional · max 2MB' : hint, style: AppTextStyles.caption),
                ],
              ),
            ),
            const SizedBox(width: 8),
            if (hasFile)
              const Icon(Icons.close, size: 16, color: AppColors.textMuted)
            else
              Icon(Icons.chevron_right, size: 18, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }
}
