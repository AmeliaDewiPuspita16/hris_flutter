import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_card.dart';
import '../../domain/announcement.dart';
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
  });

  final List<Announcement> announcements;
  final ValueChanged<Announcement>? onTapAnnouncement;

  /// Cuma HR Publisher yang boleh menambah pengumuman baru.
  final bool canCreate;
  final VoidCallback? onCreateTap;

  @override
  Widget build(BuildContext context) {
    // Publisher tetap lihat header + tombol "+ New" walau daftarnya masih
    // kosong, supaya ada jalan masuk buat bikin pengumuman pertama.
    if (announcements.isEmpty && !canCreate) return const SizedBox.shrink();

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
          if (announcements.isEmpty)
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

  final Announcement announcement;
  final ValueChanged<Announcement>? onTap;

  @override
  Widget build(BuildContext context) {
    final body = announcement.body;
    final handler = onTap;

    return InkWell(
      onTap: handler == null ? null : () => handler(announcement),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _TagChip(tag: announcement.tag),
                const SizedBox(width: 8),
                Text(
                  announcement.time,
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
              announcement.title,
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
                style: const TextStyle(
                  fontFamily: AppTextStyles.fontFamily,
                  fontSize: 12,
                  color: AppColors.textMuted,
                  height: 1.4,
                ),
              ),
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
