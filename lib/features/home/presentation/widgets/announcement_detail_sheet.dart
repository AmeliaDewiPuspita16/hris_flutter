import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../domain/announcement.dart';
import '../../domain/published_announcement.dart';

/// Isi lengkap satu pengumuman, dibuka saat kartunya diketuk.
///
/// Berbeda dari kartu di daftar, di sini waktunya ditampilkan pasti
/// ("16 Sep 2026, 10:30") — bukan relatif — dan seluruh lampiran foto
/// ditampilkan penuh.
class AnnouncementDetailSheet extends StatelessWidget {
  const AnnouncementDetailSheet({super.key, required this.announcement});

  final PublishedAnnouncement announcement;

  /// Membuka modal ini di atas [context].
  static Future<void> show(
    BuildContext context,
    PublishedAnnouncement announcement,
  ) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AnnouncementDetailSheet(announcement: announcement),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tag = AnnouncementTag.forDepartment(announcement.department);
    final body = announcement.body;
    final postedBy = announcement.postedByName;

    // URL yang tidak bisa dipakai disaring lebih dulu supaya tidak ada
    // kotak gambar kosong yang menggantung di layar.
    final photos = announcement.photos
        .where((photo) => photo.displayUrl.isNotEmpty)
        .toList();

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            children: [
              _Handle(),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 12, 4),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Announcement',
                        style: AppTextStyles.h2,
                      ),
                    ),
                    InkWell(
                      onTap: () => Navigator.of(context).pop(),
                      borderRadius: BorderRadius.circular(16),
                      child: const Padding(
                        padding: EdgeInsets.all(8),
                        child: Icon(
                          Icons.close,
                          size: 20,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                  children: [
                    _TagChip(tag: tag),
                    const SizedBox(height: 12),
                    Text(
                      announcement.title,
                      style: const TextStyle(
                        fontFamily: AppTextStyles.fontFamily,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppColors.text,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      [
                        DateFormatter.dateTimeID(announcement.createdAt),
                        if (postedBy != null) 'oleh $postedBy',
                      ].join(' · '),
                      style: const TextStyle(
                        fontFamily: AppTextStyles.fontFamily,
                        fontSize: 11,
                        color: AppColors.textMuted,
                      ),
                    ),
                    if (body != null) ...[
                      const SizedBox(height: 16),
                      Text(
                        body,
                        style: const TextStyle(
                          fontFamily: AppTextStyles.fontFamily,
                          fontSize: 13,
                          color: AppColors.textMid,
                          height: 1.5,
                        ),
                      ),
                    ],
                    if (photos.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      for (final photo in photos)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _DetailPhoto(
                            key: ValueKey('detail-photo-${photo.id}'),
                            url: photo.displayUrl,
                          ),
                        ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Handle extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 4,
      margin: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.border,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}

class _TagChip extends StatelessWidget {
  const _TagChip({required this.tag});

  final AnnouncementTag tag;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
      ),
    );
  }
}

/// Satu lampiran foto, dengan penanda saat gambarnya gagal dimuat.
class _DetailPhoto extends StatelessWidget {
  const _DetailPhoto({super.key, required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Image.network(
        url,
        width: double.infinity,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return Container(
            height: 180,
            color: AppColors.neutralBg,
            alignment: Alignment.center,
            child: const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          );
        },
        errorBuilder: (context, error, stack) => Container(
          height: 120,
          color: AppColors.neutralBg,
          alignment: Alignment.center,
          child: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.image_not_supported_outlined,
                size: 22,
                color: AppColors.textMuted,
              ),
              SizedBox(height: 6),
              Text(
                'Foto tidak bisa dimuat',
                style: TextStyle(
                  fontFamily: AppTextStyles.fontFamily,
                  fontSize: 11,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
