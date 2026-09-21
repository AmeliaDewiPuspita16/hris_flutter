import 'package:flutter/material.dart';

import '../../../../../../core/theme/app_colors.dart';
import '../../../../../../core/theme/app_text_styles.dart';
import '../../domain/pr_attachment.dart';

/// Satu lampiran PR beserta tombol bukanya.
///
/// Lampiran bisa berupa berkas yang diunggah maupun tautan — keduanya dibuka
/// dengan cara yang sama, tapi ikonnya dibedakan supaya jelas yang mana yang
/// akan membawa keluar aplikasi ke halaman web.
class PrAttachmentTile extends StatelessWidget {
  const PrAttachmentTile({
    super.key,
    required this.attachment,
    required this.onOpen,
    this.showDivider = true,
  });

  final PrAttachment attachment;

  /// Null bila URL-nya tidak bisa dipakai — tombolnya ikut dimatikan
  /// daripada menawarkan tindakan yang pasti gagal.
  final VoidCallback? onOpen;

  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    // Tautan tidak punya ukuran berkas; keterangannya diisi kategori supaya
    // barisnya tidak menyisakan ruang kosong.
    final subtitle = attachment.sizeLabel ??
        (attachment.isLink ? 'Tautan' : attachment.category ?? '');

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        border: showDivider
            ? const Border(bottom: BorderSide(color: AppColors.border))
            : null,
      ),
      child: Row(
        children: [
          Icon(
            attachment.isLink
                ? Icons.link_outlined
                : Icons.insert_drive_file_outlined,
            size: 18,
            color: AppColors.primary,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  attachment.label,
                  style: AppTextStyles.body.copyWith(fontSize: 12.5),
                ),
                if (subtitle.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(subtitle, style: AppTextStyles.caption),
                ],
              ],
            ),
          ),
          IconButton(
            onPressed: onOpen,
            visualDensity: VisualDensity.compact,
            tooltip: 'Buka lampiran',
            icon: Icon(
              Icons.open_in_new,
              size: 18,
              color: onOpen == null ? AppColors.textMuted : AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}
