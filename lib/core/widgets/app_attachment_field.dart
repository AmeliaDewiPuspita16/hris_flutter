import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import 'field_label_row.dart';

/// Field unggah lampiran bergaya "tap to upload" dengan preview nama file,
/// dipakai untuk field "Attachment (optional)" di form-form pengajuan.
///
/// Belum terhubung ke image_picker/file_picker sungguhan — memilih file
/// disimulasikan lewat [onTap] yang di-toggle oleh pemanggil (lihat contoh
/// pola serupa di `ajukan_tab.dart`), supaya alur & tampilannya sudah bisa
/// dicoba tanpa menambah dependency baru dulu. Tinggal ganti isi handler
/// [onTap] dengan pemanggilan image_picker begitu paket itu ditambahkan.
class AppAttachmentField extends StatelessWidget {
  const AppAttachmentField({
    super.key,
    required this.label,
    required this.fileName,
    required this.onTap,
    this.required = false,
    this.hint = 'JPG, PNG, GIF, or WEBP — max 10 MB',
  });

  final String label;

  /// Nama file yang sedang terpilih, atau null kalau belum ada lampiran.
  final String? fileName;

  /// Dipanggil baik untuk memilih maupun melepas lampiran — pemanggil yang
  /// menentukan aksinya lewat nilai [fileName] saat ini.
  final VoidCallback onTap;
  final bool required;
  final String hint;

  @override
  Widget build(BuildContext context) {
    final hasFile = fileName != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FieldLabelRow(label: label, required: required),
        const SizedBox(height: 6),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: hasFile ? AppColors.presentBg : const Color(0xFFFAFAFA),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: hasFile ? AppColors.presentMid : AppColors.border,
                width: 1.5,
              ),
            ),
            child: hasFile
                ? Row(
                    children: [
                      const Icon(Icons.insert_drive_file_outlined, color: AppColors.presentMid),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          fileName!,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.body.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppColors.presentMid,
                          ),
                        ),
                      ),
                      const Icon(Icons.close, size: 18, color: AppColors.presentMid),
                    ],
                  )
                : Column(
                    children: [
                      const Icon(Icons.image_outlined, color: AppColors.textMuted, size: 26),
                      const SizedBox(height: 8),
                      Text(
                        'Tap untuk unggah',
                        style: AppTextStyles.body.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSub,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(hint, style: AppTextStyles.caption),
                    ],
                  ),
          ),
        ),
      ],
    );
  }
}
