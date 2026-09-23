import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/tap_fade.dart';
import '../../domain/announcement.dart';
import '../../domain/published_announcement.dart';
import 'section_header.dart';

/// Daftar pengumuman perusahaan.
///
/// Semua baris berbagi satu kartu dan dipisah garis tipis, bukan kartu
/// sendiri-sendiri — supaya terbaca sebagai satu daftar, bukan tumpukan
/// kotak yang saling bersaing.
class AnnouncementSection extends StatelessWidget {
  const AnnouncementSection({
    super.key,
    required this.announcements,
    this.onTapAnnouncement,
    this.canCreate = false,
    this.onCreateTap,
    this.isLoading = false,
    this.errorMessage,
    this.onRetry,
  });

  final List<PublishedAnnouncement> announcements;
  final ValueChanged<PublishedAnnouncement>? onTapAnnouncement;

  /// Cuma HR Publisher yang boleh menambah pengumuman baru.
  final bool canCreate;
  final VoidCallback? onCreateTap;

  /// Daftar sedang diambil dari server.
  final bool isLoading;

  /// Alasan pengambilan gagal, sudah siap ditampilkan.
  final String? errorMessage;

  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final hasError = errorMessage != null;

    // Publisher tetap lihat header + tombol "+ New" walau daftarnya masih
    // kosong, supaya ada jalan masuk buat bikin pengumuman pertama. Keadaan
    // memuat dan gagal selalu ditampilkan — kegagalan tidak boleh
    // disembunyikan seolah-olah memang tidak ada pengumuman.
    if (announcements.isEmpty && !canCreate && !isLoading && !hasError) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SectionHeader(
            title: 'Announcements',
            actionLabel: canCreate ? '+ New' : null,
            onActionTap: canCreate ? onCreateTap : null,
          ),
          const SizedBox(height: 12),
          if (isLoading)
            const AppCard(
              padding: EdgeInsets.symmetric(vertical: 24, horizontal: 16),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else if (hasError)
            _AnnouncementError(message: errorMessage!, onRetry: onRetry)
          else if (announcements.isEmpty)
            AppCard(
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
              child: const Center(
                child: Text(
                  'No announcements yet',
                  style: TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    fontSize: 12,
                    color: AppColors.textMuted,
                  ),
                ),
              ),
            )
          else
            AppCard(
              child: ClipRRect(
                // Memotong efek sentuh tiap baris agar tidak melewati sudut kartu.
                borderRadius: BorderRadius.circular(12),
                child: Column(
                  children: [
                    for (var i = 0; i < announcements.length; i++) ...[
                      if (i > 0)
                        const Divider(
                          height: 1,
                          thickness: 1,
                          indent: 16,
                          endIndent: 16,
                          color: AppColors.border,
                        ),
                      _AnnouncementTile(
                        announcement: announcements[i],
                        onTap: onTapAnnouncement,
                      ),
                    ],
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _AnnouncementTile extends StatelessWidget {
  const _AnnouncementTile({required this.announcement, this.onTap});

  final PublishedAnnouncement announcement;
  final ValueChanged<PublishedAnnouncement>? onTap;

  /// Paling banyak sekian thumbnail yang muat di satu baris kartu; sisanya
  /// diringkas jadi penanda "+N".
  static const _maxThumbnails = 3;

  @override
  Widget build(BuildContext context) {
    final display = Announcement.fromPublished(announcement);
    final body = display.body;
    final handler = onTap;

    // URL cacat disaring lebih dulu supaya tidak ada kotak kosong di kartu.
    final photos = announcement.photos
        .where((photo) => photo.displayUrl.isNotEmpty)
        .toList();

    return InkWell(
      onTap: handler == null ? null : () => handler(announcement),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _TagChip(tag: display.tag),
                const SizedBox(width: 8),
                Text(
                  display.time,
                  style: const TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    fontSize: 11,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              display.title,
              style: const TextStyle(
                fontFamily: AppTextStyles.fontFamily,
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                color: AppColors.text,
                height: 1.35,
              ),
            ),
            if (body != null) ...[
              const SizedBox(height: 4),
              Text(
                body,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: AppTextStyles.fontFamily,
                  fontSize: 12,
                  color: AppColors.textMuted,
                  height: 1.4,
                ),
              ),
            ],
            if (photos.isNotEmpty) ...[
              const SizedBox(height: 10),
              _ThumbnailStrip(photos: photos, maxVisible: _maxThumbnails),
            ],
          ],
        ),
      ),
    );
  }
}

class _TagChip extends StatelessWidget {
  const _TagChip({required this.tag});

  final AnnouncementTag tag;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: tag.background,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        tag.label,
        style: TextStyle(
          fontFamily: AppTextStyles.fontFamily,
          fontSize: 10,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.5,
          color: tag.color,
        ),
      ),
    );
  }
}

/// Kegagalan memuat daftar, dengan jalan keluar untuk mencoba lagi.
class _AnnouncementError extends StatelessWidget {
  const _AnnouncementError({required this.message, this.onRetry});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.error_outline,
                size: 16,
                color: AppColors.rejected,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    fontSize: 12,
                    color: AppColors.rejected,
                  ),
                ),
              ),
            ],
          ),
          if (onRetry != null) ...[
            const SizedBox(height: 8),
            InkWell(
              onTap: onRetry,
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 4),
                child: Text(
                  'Coba lagi',
                  style: TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryMid,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Deretan thumbnail kecil di kartu daftar. Sisa foto yang tidak muat
/// diringkas jadi penanda "+N" alih-alih memanjangkan kartu.
class _ThumbnailStrip extends StatelessWidget {
  const _ThumbnailStrip({required this.photos, required this.maxVisible});

  final List<AnnouncementPhotoRef> photos;
  final int maxVisible;

  @override
  Widget build(BuildContext context) {
    final visible = photos.take(maxVisible).toList();
    final hidden = photos.length - visible.length;

    return Row(
      children: [
        for (final photo in visible)
          Padding(
            padding: const EdgeInsets.only(right: 6),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Image.network(
                photo.displayUrl,
                width: 44,
                height: 44,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stack) => Container(
                  width: 44,
                  height: 44,
                  color: AppColors.neutralBg,
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.image_not_supported_outlined,
                    size: 14,
                    color: AppColors.textMuted,
                  ),
                ),
              ),
            ),
          ),
        if (hidden > 0)
          Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.neutralBg,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              '+$hidden',
              style: const TextStyle(
                fontFamily: AppTextStyles.fontFamily,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.textMid,
              ),
            ),
          ),
      ],
    );
  }
}
