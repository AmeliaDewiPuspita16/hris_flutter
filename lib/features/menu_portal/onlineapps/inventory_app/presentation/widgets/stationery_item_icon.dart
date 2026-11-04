import 'package:flutter/material.dart';

import '../../../../../../core/theme/app_colors.dart';

/// Ikon + warna untuk satu barang stationery.
///
/// Barang stationery tidak punya kategori di data, dan daftarnya tidak tentu
/// (bisa bertambah kapan saja). Jadi jenisnya ditebak dari KATA di nama barang
/// ("AMPLOP A4 COKLAT" -> surat, "PENA JOYKO" -> pena, ...). Barang yang tidak
/// dikenali jatuh ke ikon umum [_other], jadi tidak ada kartu tanpa ikon dan
/// barang baru dari server tetap aman tampil.
///
/// Menambah jenis baru cukup menambah satu baris di [_rules].
class StationeryItemStyle {
  const StationeryItemStyle(this.icon, this.color, this.background);

  final IconData icon;
  final Color color;
  final Color background;

  static final _words = RegExp(r'[A-Z0-9]+');

  /// Pencocokan per KATA utuh (bukan potongan teks) supaya "LEM" tidak ikut
  /// cocok dengan kata seperti "ELEMEN". Aturan yang lebih atas menang.
  static List<(Set<String>, StationeryItemStyle Function())> get _rules => [
        (
          {'AMPLOP', 'ENVELOPE', 'SURAT'},
          () => StationeryItemStyle(
                Icons.mail_outline_rounded,
                AppColors.violet,
                AppColors.violetBg,
              )
        ),
        (
          {'SIGN', 'STICKY', 'POST'},
          () => StationeryItemStyle(
                Icons.sticky_note_2_outlined,
                AppColors.present,
                AppColors.presentBg,
              )
        ),
        (
          {'BATERAI', 'BATTERY', 'BATRE', 'ALKALINE'},
          () => StationeryItemStyle(
                Icons.battery_full_rounded,
                AppColors.orange,
                AppColors.orangeBg,
              )
        ),
        (
          {'BENDERA', 'FLAG', 'UMBUL'},
          () => StationeryItemStyle(
                Icons.flag_outlined,
                AppColors.rejected,
                AppColors.rejectedBg,
              )
        ),
        (
          {'ISOLASI', 'LAKBAN', 'SELOTIP', 'TAPE', 'LEM', 'GLUE'},
          () => StationeryItemStyle(
                Icons.album_outlined,
                AppColors.estRequest,
                AppColors.estRequestBg,
              )
        ),
        (
          {'CLIP', 'KLIP', 'BINDER', 'STAPLES', 'STAPLER', 'HECHTER'},
          () => StationeryItemStyle(
                Icons.attach_file_rounded,
                AppColors.accent,
                AppColors.accentBg,
              )
        ),
        (
          {
            'PENA', 'PULPEN', 'PEN', 'PENSIL', 'BOLPOIN', 'BALLPOINT',
            'SPIDOL', 'MARKER', 'HIGHLIGHTER', 'PENGHAPUS', 'TIPEX',
            'GOBY', 'JOYKO', 'KENKO', 'SNOWMAN', 'PILOT', 'FABER', 'CASTELL',
          },
          () => StationeryItemStyle(
                Icons.edit_outlined,
                AppColors.itRequest,
                AppColors.itRequestBg,
              )
        ),
        (
          {'GUNTING', 'CUTTER', 'PISAU', 'SCISSORS'},
          () => StationeryItemStyle(
                Icons.content_cut_rounded,
                AppColors.neutral,
                AppColors.neutralBg,
              )
        ),
        (
          {'PENGGARIS', 'RULER', 'MISTAR'},
          () => StationeryItemStyle(
                Icons.straighten_rounded,
                AppColors.neutral,
                AppColors.neutralBg,
              )
        ),
        (
          {'MAP', 'FOLDER', 'ORDNER', 'FILE', 'MAGAZINE', 'HOLDER'},
          () => StationeryItemStyle(
                Icons.folder_outlined,
                AppColors.primaryText,
                AppColors.primaryLight,
              )
        ),
        (
          {
            'KERTAS', 'HVS', 'FOLIO', 'NOTA', 'KWITANSI', 'FORM', 'BUKU',
            'NOTES', 'MEMO', 'KARTON', 'STRUK',
          },
          () => StationeryItemStyle(
                Icons.description_outlined,
                AppColors.teal,
                AppColors.tealBg,
              )
        ),
      ];

  /// Ikon umum untuk barang yang jenisnya tidak dikenali.
  static StationeryItemStyle get _other => StationeryItemStyle(
        Icons.inventory_2_outlined,
        AppColors.primaryText,
        AppColors.primaryLight,
      );

  static StationeryItemStyle of(String itemName) {
    final words =
        _words.allMatches(itemName.toUpperCase()).map((m) => m.group(0)!).toSet();

    for (final (keywords, style) in _rules) {
      if (words.any(keywords.contains)) return style();
    }
    return _other;
  }
}

/// Kotak ikon barang di kiri kartu (gaya sama dengan ikon berkas di tile
/// IMS Document).
class StationeryItemIcon extends StatelessWidget {
  const StationeryItemIcon({super.key, required this.itemName, this.size = 42});

  final String itemName;
  final double size;

  @override
  Widget build(BuildContext context) {
    final style = StationeryItemStyle.of(itemName);

    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: style.background,
        borderRadius: BorderRadius.circular(size * 0.29),
      ),
      child: Icon(style.icon, size: size * 0.52, color: style.color),
    );
  }
}
