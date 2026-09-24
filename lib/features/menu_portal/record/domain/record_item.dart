import 'package:flutter/widgets.dart';

/// Satu baris kategori di halaman Records (Company Profile, Contract, dst).
class RecordItem {
  const RecordItem({
    required this.icon,
    required this.label,
    required this.owners,
    required this.color,
    required this.background,
    required this.onTap,
  });

  final IconData icon;
  final String label;

  /// Nama-nama PIC/owner kategori ini, ditampilkan sebagai badge — bisa
  /// lebih dari satu, mengikuti tampilan web "Records" (mis. Company
  /// Profile dipegang Nanda & Fadel).
  final List<String> owners;

  /// Warna ikon dan latar kotak ikon di belakangnya.
  final Color color;
  final Color background;

  final VoidCallback onTap;
}
