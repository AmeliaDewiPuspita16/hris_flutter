import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// Label field di bagian atas tiap section form. Field wajib ditandai
/// bintang merah tepat setelah teks label ("Location *"), seperti
/// `AttachmentField` dan `UploadField` di modul Pengajuan.
///
/// Sebelumnya digandakan identik di 3 modul form (HSE Work Request, EST
/// Request, IT Request); disatukan ke sini karena isinya sama persis dan
/// tidak spesifik ke satu modul manapun.
class FieldLabelRow extends StatelessWidget {
  const FieldLabelRow({
    super.key,
    required this.label,
    this.required = false,
  });

  final String label;

  /// true = tampilkan bintang merah setelah [label].
  final bool required;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text.rich(
        TextSpan(
          text: label,
          children: [
            if (required)
              TextSpan(
                text: ' *',
                style: TextStyle(color: AppColors.rejected),
              ),
          ],
        ),
        style: AppTextStyles.sectionTitle.copyWith(
          fontSize: 11,
          letterSpacing: 0.3,
          color: AppColors.textMuted,
        ),
      ),
    );
  }
}
