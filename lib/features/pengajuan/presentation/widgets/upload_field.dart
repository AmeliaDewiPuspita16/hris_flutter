import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

/// Placeholder unggah berkas — belum benar-benar membuka file picker, tap
/// cuma menyisipkan/menghapus [defaultFile] sebagai nama berkas dummy.
/// Dipakai tab Ajukan untuk lampiran (mis. surat dokter, bukti pemeriksaan).
class UploadField extends StatelessWidget {
  const UploadField({
    super.key,
    required this.label,
    required this.fileName,
    required this.defaultFile,
    required this.onChanged,
    this.required = false,
  });

  final String label;
  final String? fileName;
  final String defaultFile;
  final ValueChanged<String?> onChanged;
  final bool required;

  @override
  Widget build(BuildContext context) {
    final hasFile = fileName != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            style: AppTextStyles.label,
            children: [
              TextSpan(text: label),
              if (required)
                const TextSpan(text: ' *', style: TextStyle(color: AppColors.rejected)),
            ],
          ),
        ),
        const SizedBox(height: 6),
        InkWell(
          onTap: () => onChanged(hasFile ? null : defaultFile),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: hasFile ? AppColors.presentBg : const Color(0xFFFAFAFA),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: hasFile ? AppColors.presentMid : AppColors.border,
                width: 2,
              ),
            ),
            child: hasFile
                ? Text(
                    '📄 $fileName',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.presentMid,
                    ),
                  )
                : const Column(
                    children: [
                      Icon(Icons.upload_outlined, color: AppColors.textMuted),
                      SizedBox(height: 8),
                      Text(
                        'Tap to upload',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSub,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'PDF, JPG, PNG · Max. 5MB',
                        style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                      ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }
}
