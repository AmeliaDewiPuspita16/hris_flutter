import 'package:flutter/widgets.dart';

/// Satu baris di bagian "Aktivitas Terbaru".
class ActivityEntry {
  const ActivityEntry({
    required this.icon,
    required this.title,
    required this.description,
    required this.time,
    required this.color,
    required this.background,
  });

  final IconData icon;
  final String title;
  final String description;

  /// Waktu relatif, mis. "2 jam lalu".
  final String time;

  /// Warna ikon dan kotak di belakangnya.
  final Color color;
  final Color background;
}
