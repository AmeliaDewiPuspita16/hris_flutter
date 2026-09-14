import 'package:flutter/widgets.dart';

import '../../../core/theme/app_colors.dart';

/// Label departemen penerbit pengumuman, mis. HR atau GA.
///
/// Dibuat sebagai konstanta bernama supaya satu departemen selalu tampil
/// dengan warna yang sama di seluruh aplikasi.
class AnnouncementTag {
  const AnnouncementTag({
    required this.label,
    required this.color,
    required this.background,
  });

  final String label;
  final Color color;
  final Color background;

  static const hr = AnnouncementTag(
    label: 'HR',
    color: AppColors.primary,
    background: AppColors.primaryLight,
  );

  static const ga = AnnouncementTag(
    label: 'GA',
    color: AppColors.accent,
    background: AppColors.accentBg,
  );

  static const it = AnnouncementTag(
    label: 'IT',
    color: AppColors.violet,
    background: AppColors.violetBg,
  );
}

/// Satu pengumuman di bagian "Announcements".
class Announcement {
  const Announcement({
    required this.tag,
    required this.time,
    required this.title,
    this.body,
  });

  final AnnouncementTag tag;

  /// Waktu relatif, mis. "2h ago".
  final String time;

  final String title;

  /// Keterangan tambahan. Boleh kosong — pengumuman singkat cukup judulnya.
  final String? body;
}
