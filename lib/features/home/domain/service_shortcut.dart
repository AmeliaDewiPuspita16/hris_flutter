import 'package:flutter/widgets.dart';

/// Satu ikon pintasan di bagian "Layanan".
class ServiceShortcut {
  const ServiceShortcut({
    required this.icon,
    required this.label,
    required this.color,
    required this.background,
    required this.onTap,
  });

  final IconData icon;
  final String label;

  /// Warna ikon dan lingkaran di belakangnya.
  final Color color;
  final Color background;

  final VoidCallback onTap;
}
