import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

/// Field lampiran bergaya kompak (ikon paperclip + placeholder sebaris),
/// beda dari [UploadField] yang dropzone besar — dipakai saat lampirannya
/// opsional, misalnya dokumen pendukung Cuti Tahunan. Sama seperti
/// [UploadField], ini masih placeholder: tap hanya menyisipkan/menghapus
/// [defaultFile] sebagai nama berkas dummy, belum membuka file picker asli.
class AttachmentField extends StatelessWidget {
  const AttachmentField({
    super.key,
    required this.fileName,
    required this.onChanged,
    this.label = 'Attachment',
    this.defaultFile = 'lampiran.pdf',
    this.hint = 'doc, jpg, ods, png, txt  max size: 10,000 KByte',
    this.required = false,
  });

  final String label;
  final String? fileName;
  final String defaultFile;
  final String hint;
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
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border, width: 1.5),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.attach_file,
                  size: 18,
                  color: hasFile ? AppColors.primary : AppColors.textMuted,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    hasFile ? fileName! : 'Additional Document',
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: hasFile ? FontWeight.w700 : FontWeight.w500,
                      color: hasFile ? AppColors.text : AppColors.textMuted,
                    ),
                  ),
                ),
                if (hasFile)
                  Icon(Icons.close, size: 16, color: AppColors.textMuted),
              ],
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          hint,
          style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
        ),
      ],
    );
  }
}
