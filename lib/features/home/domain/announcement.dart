import 'package:flutter/widgets.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/date_formatter.dart';
import '../../shared/domain/department.dart';
import 'published_announcement.dart';

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

  /// Palet warna badge. API departemen tidak mengirim warna, jadi dipilih
  /// di sisi aplikasi.
  static const _palette = [
    (color: AppColors.primary, background: AppColors.primaryLight),
    (color: AppColors.accent, background: AppColors.accentBg),
    (color: AppColors.violet, background: AppColors.violetBg),
    (color: AppColors.teal, background: AppColors.tealBg),
  ];

  /// Badge untuk sebuah departemen.
  ///
  /// Warnanya diturunkan dari [Department.id], bukan dari posisi dalam
  /// sebuah daftar — jadi satu departemen selalu tampil dengan warna yang
  /// sama di layar mana pun, apa pun urutan datanya.
  factory AnnouncementTag.forDepartment(Department department) {
    final palette = _palette[department.id.abs() % _palette.length];
    return AnnouncementTag(
      label: department.name,
      color: palette.color,
      background: palette.background,
    );
  }
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

  /// Memetakan pengumuman dari server ke bentuk yang ditampilkan daftar.
  factory Announcement.fromPublished(PublishedAnnouncement published) {
    return Announcement(
      tag: AnnouncementTag.forDepartment(published.department),
      time: DateFormatter.relative(published.createdAt),
      title: published.title,
      body: published.body,
    );
  }
}
