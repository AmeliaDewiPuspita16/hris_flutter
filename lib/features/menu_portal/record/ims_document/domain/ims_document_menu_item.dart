import 'package:flutter/widgets.dart';

/// Satu opsi pada bottom sheet "IMS Document" (Master Document File,
/// Request, dst)
///
/// Field icon/color/background sama polanya dengan [RecordItem]
class ImsDocumentMenuItem {
  const ImsDocumentMenuItem({
    required this.icon,
    required this.label,
    required this.description,
    required this.color,
    required this.background,
    required this.onTap,
  });

  final IconData icon;

  final String label;

  /// Baris kecil di bawah label, mis. "Manual, SOP, WI, Form, ANNEX, Form
  /// Template" untuk Master Document File.
  final String description;

  /// Warna icon, sekaligus warna aksen tile.
  final Color color;

  /// Warna background kotak icon (biasanya versi terang dari [color]).
  final Color background;

  final VoidCallback onTap;
}
