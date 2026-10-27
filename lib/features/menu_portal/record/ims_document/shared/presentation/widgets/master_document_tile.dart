import 'package:flutter/material.dart';

import '../../../../../../../core/theme/app_colors.dart';
import '../../../../../../../core/theme/app_text_styles.dart';
import '../../../../../../../core/utils/date_formatter.dart';
import '../../../../../../../core/widgets/app_card.dart';
import '../../../../../../../core/widgets/status_badge.dart';
import '../../domain/master_document.dart';

/// Satu baris dokumen master pada tab Manual/SOP/WI/dst.
///
/// Seluruh kartu bisa di-tap untuk membaca PDF-nya di aplikasi lewat
/// [onView] — dokumen hanya bisa dilihat, tidak diunduh. Dokumen non-PDF
/// (Form Template) tidak bisa dibuka: kartunya tidak bisa di-tap dan diberi
/// keterangan "Preview not available".
class MasterDocumentTile extends StatelessWidget {
  const MasterDocumentTile({
    super.key,
    required this.document,
    required this.onView,
  });

  final MasterDocument document;
  final ValueChanged<MasterDocument> onView;

  @override
  Widget build(BuildContext context) {
    final viewable = document.isPdf;
    final updatedAt = document.updatedAt;

    return AppCard(
      padding: const EdgeInsets.fromLTRB(14, 14, 10, 14),
      onTap: viewable ? () => onView(document) : null,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _FileIcon(viewable: viewable),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  document.docNo,
                  style: AppTextStyles.body.copyWith(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  document.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.body.copyWith(
                    fontSize: 12.5,
                    height: 1.4,
                    color: AppColors.textMid,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    _HierarchyBadge(label: document.hierarchy),
                    if (updatedAt != null)
                      _MetaText(
                        icon: Icons.schedule_rounded,
                        text: 'Updated ${DateFormatter.shortDate(updatedAt)}',
                      ),
                    if (!viewable)
                      const _MetaText(
                        icon: Icons.visibility_off_outlined,
                        text: 'Preview not available',
                      ),
                  ],
                ),
              ],
            ),
          ),
          if (viewable)
            const Padding(
              padding: EdgeInsets.only(left: 4, top: 10),
              child: Icon(Icons.chevron_right_rounded, size: 22, color: AppColors.textMuted),
            ),
        ],
      ),
    );
  }
}

/// Kotak ikon berkas di kiri kartu: merah bata untuk PDF (bisa dibuka),
/// abu-abu untuk berkas lain.
class _FileIcon extends StatelessWidget {
  const _FileIcon({required this.viewable});

  final bool viewable;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 42,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: viewable ? AppColors.hseRequestBg : AppColors.neutralBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        viewable ? Icons.picture_as_pdf_outlined : Icons.insert_drive_file_outlined,
        size: 22,
        color: viewable ? AppColors.hseRequest : AppColors.neutral,
      ),
    );
  }
}

class _MetaText extends StatelessWidget {
  const _MetaText({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: AppColors.textMuted),
        const SizedBox(width: 4),
        Text(text, style: AppTextStyles.caption.copyWith(color: AppColors.textMuted)),
      ],
    );
  }
}

/// Badge kategori/departemen dokumen ("IMS", "HSE", "EST", dst).
///
/// Tab Manual semuanya "IMS" jadi satu warna cukup, tapi tab SOP (dan
/// tab lain nanti) punya banyak departemen berbeda dalam satu list — warna
/// dibedakan per departemen supaya gampang di-scan sekilas pas scroll,
/// bukan warna tunggal yang monoton. Tetap widget sendiri (bukan langsung
/// `StatusBadge.custom` di tempat pemanggilan) karena logic pemetaan kode
/// departemen → warna ini cuma relevan di sini.
class _HierarchyBadge extends StatelessWidget {
  const _HierarchyBadge({required this.label});

  final String label;

  /// Pasangan (warna teks, warna latar) per kode departemen. Kode yang
  /// belum dikenal jatuh ke [AppColors.neutral]/[AppColors.neutralBg]
  /// supaya badge baru dari data API nanti tetap aman tampil, bukan error.
  static const _palette = {
    'IMS': (AppColors.primary, AppColors.primaryLight),
    'HSE': (AppColors.itRequest, AppColors.itRequestBg),
    'EST': (AppColors.estRequest, AppColors.estRequestBg),
    'CDD': (AppColors.teal, AppColors.tealBg),
    'AML': (AppColors.violet, AppColors.violetBg),
    'POD': (AppColors.orange, AppColors.orangeBg),
    'SSD': (AppColors.accent, AppColors.accentBg),
    'HR & GA': (AppColors.primaryMid, AppColors.primaryLight),
    'GMO': (AppColors.present, AppColors.presentBg),
    'ITM': (AppColors.pending, AppColors.pendingBg),
    'CRS': (AppColors.rejected, AppColors.rejectedBg),
    'FIN': (AppColors.inProgress, AppColors.inProgressBg),
  };

  @override
  Widget build(BuildContext context) {
    final (color, background) =
        _palette[label.toUpperCase()] ?? _palette[label] ?? (AppColors.neutral, AppColors.neutralBg);

    return StatusBadge.custom(label: label, color: color, background: background);
  }
}
