import 'package:flutter/material.dart';

import '../../../../../../core/theme/app_colors.dart';
import '../../../../../../core/theme/app_text_styles.dart';
import '../../../../../../core/widgets/app_card.dart';
import '../../domain/master_document.dart';

/// Satu baris dokumen master pada tab Manual/SOP/WI/dst.
///
/// - "Download" langsung jalan begitu di-tap (sama seperti web — tidak ada
///   pratinjau isi berkas dulu).
/// - "Obsolete" munculin dialog konfirmasi dulu (padanan modal "Dokumen
///   Obsolete" di web) sebelum [onObsolete] dipanggil, supaya orang sadar
///   dokumen yang mau di-download sudah tidak berlaku.
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

  Future<void> _handleObsoleteTap(BuildContext context) async {
    final confirmed = await _confirmObsoleteDownload(context);
    if (confirmed) onObsolete(document);
  }

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
              label: 'Obsolete',
              onTap: () => _handleObsoleteTap(context),
              showDivider: false,
            ),
        ],
      ),
    );
  }
}

/// Badge kategori/departemen dokumen ("IMS", "HSE", "EST", dst)
///
/// Tab Manual semuanya "IMS" jadi satu warna cukup, tapi tab SOP (dan
/// tab lain nanti) punya banyak departemen berbeda dalam satu list — warna
/// dibedakan per departemen supaya gampang di-scan sekilas pas scroll,
/// bukan warna tunggal yang monoton.
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

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: AppTextStyles.fontFamily,
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: color,
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

/// Dialog konfirmasi sebelum download dokumen obsolete — padanan modal
/// "Dokumen Obsolete" di web (ikon seru bulat, judul, dua paragraf
/// peringatan, tombol "Batal" & "Ya, Download").
///
/// Return `true` kalau orang menekan "Ya, Download", `false` untuk "Batal"
/// atau dialog ditutup dengan cara lain (tap di luar, tombol back).
Future<bool> _confirmObsoleteDownload(BuildContext context) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              alignment: Alignment.center,
              decoration: const BoxDecoration(color: AppColors.orangeBg, shape: BoxShape.circle),
              child: const Icon(Icons.priority_high_rounded, color: AppColors.orange, size: 30),
            ),
            const SizedBox(height: 16),
            const Text(
              'Dokumen Obsolete',
              style: TextStyle(
                fontFamily: AppTextStyles.fontFamily,
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.text,
              ),
            ),
            const SizedBox(height: 10),
            RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                style: AppTextStyles.body.copyWith(fontSize: 12.5, color: AppColors.textMid, height: 1.5),
                children: const [
                  TextSpan(text: 'Dokumen yang akan Anda download adalah '),
                  TextSpan(
                    text: 'dokumen yang sudah tidak berlaku (obsolete)',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  TextSpan(text: '.'),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Dokumen ini hanya boleh digunakan sebagai referensi historis. '
              'Jangan gunakan dokumen ini sebagai acuan proses yang aktif.',
              textAlign: TextAlign.center,
              style: AppTextStyles.body.copyWith(fontSize: 12.5, color: AppColors.textMuted, height: 1.5),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(dialogContext).pop(false),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textMid,
                      side: const BorderSide(color: AppColors.border),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text(
                      'Batal',
                      style: TextStyle(fontFamily: AppTextStyles.fontFamily, fontWeight: FontWeight.w700, fontSize: 13),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.of(dialogContext).pop(true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.present,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      elevation: 0,
                    ),
                    icon: const Icon(Icons.file_download_outlined, size: 16),
                    label: const Text(
                      'Ya, Download',
                      style: TextStyle(fontFamily: AppTextStyles.fontFamily, fontWeight: FontWeight.w700, fontSize: 13),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );

  return confirmed ?? false;
}
