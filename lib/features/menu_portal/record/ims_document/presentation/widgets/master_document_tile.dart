import 'package:flutter/material.dart';

import '../../../../../../core/theme/app_colors.dart';
import '../../../../../../core/theme/app_text_styles.dart';
import '../../../../../../core/widgets/app_card.dart';
import '../../domain/master_document.dart';

/// Satu baris dokumen master pada tab Manual/SOP/WI/dst.
///
/// Direstyle mengikuti pola `PrCard` + `PrAttachmentTile` di Procurement
/// supaya konsisten satu portal: badge pil kecil (bukan kotak), tipografi
/// berjenjang, divider tipis, dan aksi buka berkas sebagai baris
/// ikon + label (bukan tombol solid selebar kartu seperti sebelumnya).
///
/// Tabel di web (NO/DOC NO/TITLE/HIERARCHY DOC/DOCUMENT) dipadatkan jadi
/// kartu — layar sempit tidak cukup untuk kolom sebanyak itu berdampingan.
class MasterDocumentTile extends StatelessWidget {
  const MasterDocumentTile({
    super.key,
    required this.document,
    required this.onDownload,
    required this.onObsolete,
  });

  final MasterDocument document;
  final ValueChanged<MasterDocument> onDownload;
  final ValueChanged<MasterDocument> onObsolete;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  document.docNo,
                  style: AppTextStyles.body.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _HierarchyBadge(label: document.hierarchy),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            document.title,
            style: AppTextStyles.body.copyWith(fontSize: 13, height: 1.4),
          ),
          const SizedBox(height: 10),
          _FileActionRow(
            icon: Icons.file_download_outlined,
            label: 'Download',
            onTap: () => onDownload(document),
            showDivider: document.obsoleteUrl != null,
          ),
          if (document.obsoleteUrl != null)
            _FileActionRow(
              icon: Icons.history_outlined,
              label: 'Versi Obsolete',
              onTap: () => onObsolete(document),
              showDivider: false,
            ),
        ],
      ),
    );
  }
}

/// Badge kategori dokumen ("IMS", "HSE", dst) — padanan `PrStatusBadge`,
/// pil bulat kecil, bukan kotak sudut tajam seperti sebelumnya.
class _HierarchyBadge extends StatelessWidget {
  const _HierarchyBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.estRequestBg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontFamily: AppTextStyles.fontFamily,
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: AppColors.estRequest,
        ),
      ),
    );
  }
}

/// Satu baris aksi berkas (Download / Obsolete) — padanan `PrAttachmentTile`:
/// ikon + label di kiri, chevron kecil di kanan, seluruh baris bisa di-tap.
/// Menggantikan tombol solid oranye selebar kartu di versi sebelumnya.
class _FileActionRow extends StatelessWidget {
  const _FileActionRow({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.showDivider,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: showDivider
            ? const Border(bottom: BorderSide(color: AppColors.border))
            : null,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              Icon(icon, size: 17, color: AppColors.primary),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  style: AppTextStyles.body.copyWith(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const Icon(Icons.chevron_right, size: 18, color: AppColors.textMuted),
            ],
          ),
        ),
      ),
    );
  }
}
