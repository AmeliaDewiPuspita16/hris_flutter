import 'package:flutter/material.dart';

import '../../../../../../core/theme/app_colors.dart';
import '../../../../../../core/theme/app_text_styles.dart';
import '../../domain/pr_attachment.dart';

/// Satu lampiran PR beserta tombol unduhnya.
class PrAttachmentTile extends StatelessWidget {
  const PrAttachmentTile({
    super.key,
    required this.attachment,
    required this.onDownload,
  });

  final PrAttachment attachment;
  final VoidCallback onDownload;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(
          Icons.insert_drive_file_outlined,
          size: 18,
          color: AppColors.primary,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                attachment.fileName,
                style: AppTextStyles.body.copyWith(fontSize: 12.5),
              ),
              const SizedBox(height: 2),
              Text(attachment.sizeLabel, style: AppTextStyles.caption),
            ],
          ),
        ),
        IconButton(
          onPressed: onDownload,
          visualDensity: VisualDensity.compact,
          icon: const Icon(
            Icons.file_download_outlined,
            size: 18,
            color: AppColors.primary,
          ),
        ),
      ],
    );
  }
}
