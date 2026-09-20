import 'package:flutter/material.dart';

import '../../../../../../../core/theme/app_colors.dart';
import '../../../../../../../core/theme/app_text_styles.dart';

/// Field lampiran ringkas satu baris (ikon + judul + keterangan) khusus
/// untuk form Add Request.
///
/// Sengaja dibuat sebagai widget sendiri, bukan mengubah `AppAttachmentField`
/// yang sudah dipakai form-form pengajuan lain — supaya restyle di sini
/// tidak ikut mengubah tampilan form lain yang memakai widget itu.
class AttachmentRowField extends StatelessWidget {
  const AttachmentRowField({
    super.key,
    required this.fileName,
    required this.onTap,
    this.maxFiles = 1,
  });

  final String? fileName;
  final VoidCallback onTap;

  /// Jumlah lampiran maksimum — dipakai untuk keterangan "N left" di kanan.
  final int maxFiles;

  @override
  Widget build(BuildContext context) {
    final hasFile = fileName != null;
    final filesLeft = hasFile ? maxFiles - 1 : maxFiles;

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
                hasFile ? Icons.insert_drive_file_outlined : Icons.attach_file,
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
                    hasFile ? fileName! : 'Add photo or file',
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 1),
                  const Text('Optional · max 10MB', style: AppTextStyles.caption),
                ],
              ),
            ),
            const SizedBox(width: 8),
            if (hasFile)
              const Icon(Icons.close, size: 16, color: AppColors.textMuted)
            else
              Text('$filesLeft left', style: AppTextStyles.caption),
          ],
        ),
      ),
    );
  }
}