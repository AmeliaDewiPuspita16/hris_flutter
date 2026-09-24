import 'package:flutter/widgets.dart';

/// Satu kartu pintasan di bagian "Main Menu".
class ServiceShortcut {
  const ServiceShortcut({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.background,
    required this.onTap,
    this.featured = false,
  });

  final IconData icon;
  final String label;

  /// Keterangan singkat di bawah [label], mis. "Database & Files".
  final String subtitle;

  /// Warna ikon dan lingkaran di belakangnya (untuk kartu non-[featured]).
  final Color color;
  final Color background;

  /// Kartu pertama/utama ditandai lewat ini supaya tampil menonjol (latar
  /// hijau solid) dibanding kartu lain yang bernuansa pastel — mengikuti
  /// pola desain "Main Menu" di Beranda.
  final bool featured;

  final VoidCallback onTap;
}
