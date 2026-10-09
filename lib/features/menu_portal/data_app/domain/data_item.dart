import 'package:flutter/widgets.dart';

/// Satu baris kategori di halaman Data (Award & Recognition, Budget
/// Department, dst). Bentuknya sama persis dengan `RecordItem` — folder
/// Data dan Record memang dua menu berbeda, tapi tile-nya sudah dipakai
/// bareng lewat `MenuListTile`/`OwnerBadgeRow`, jadi modelnya juga
/// disamakan biar gampang dirawat.
class DataItem {
  const DataItem({
    required this.icon,
    required this.label,
    required this.owners,
    required this.color,
    required this.background,
    required this.onTap,
  });

  final IconData icon;
  final String label;

  /// Nama-nama PIC/Owner kategori ini - bisa lebih dari satu, sama seperti record
  final List<String> owners;

  final Color color;
  final Color background;

  final VoidCallback onTap;
}
