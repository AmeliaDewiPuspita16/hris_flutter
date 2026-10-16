import 'package:flutter/widgets.dart';

/// Satu baris aplikasi di halaman Online Apps.
class OnlineAppItem {
  const OnlineAppItem({
    required this.icon,
    required this.label,
    required this.department,
    required this.color,
    required this.background,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String department;

  /// Warna ikon dan latar kotak ikon di belakangnya.
  final Color color;
  final Color background;

  /// Null = fitur belum siap: tile tampil redup dan tidak bisa diketuk
  /// (aturan sama dengan `isReady` di menu HRIS, tanpa label "Soon").
  final VoidCallback? onTap;

  bool get isReady => onTap != null;
}
