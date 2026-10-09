import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

enum AppStatus { present, pending, rejected, neutral, onProgress }

/// Badge kecil rounded — dua cara pakai:
///
/// - `StatusBadge(status: ...)` untuk status workflow tertutup ([AppStatus]:
///   disetujui/menunggu/ditolak/diproses/netral), warna & label default
///   sudah dipatenkan di [_data].
/// - `StatusBadge.custom(...)` untuk tag bebas yang bukan status workflow —
///   nama owner, kode department, tipe/kategori request, dsb — label dan
///   warnanya ditentukan sendiri oleh pemanggil, bukan dari lookup
///   [AppStatus]. Dipakai supaya tag-tag begini tidak masing-masing bikin
///   `Container` sendiri dengan padding/radius yang pelan-pelan beda-beda.
class StatusBadge extends StatelessWidget {
  const StatusBadge({super.key, required AppStatus status, this.label})
      : status = status,
        _color = null,
        _background = null;

  const StatusBadge.custom({
    super.key,
    required this.label,
    required Color color,
    required Color background,
  })  : status = null,
        _color = color,
        _background = background;

  final AppStatus? status;

  /// Override label bawaan — dipakai HSE Work Request supaya badge-nya
  /// bisa bilang "On Waiting"/"On Progress"/dst persis seperti di web,
  /// bukan cuma "Menunggu" generik yang dipakai modul lain.
  ///
  /// Untuk `.custom`, ini SELALU dipakai (bukan override) karena memang
  /// tidak ada label bawaan.
  final String? label;

  final Color? _color;
  final Color? _background;

  ({Color fg, Color bg, String label}) get _data {
    if (status == null) {
      return (fg: _color!, bg: _background!, label: label!);
    }

    switch (status!) {
      case AppStatus.present:
        return (
          fg: AppColors.present,
          bg: AppColors.presentBg,
          label: 'Disetujui'
        );
      case AppStatus.pending:
        return (
          fg: AppColors.pending,
          bg: AppColors.pendingBg,
          label: 'Menunggu'
        );
      case AppStatus.rejected:
        return (
          fg: AppColors.rejected,
          bg: AppColors.rejectedBg,
          label: 'Ditolak'
        );
      case AppStatus.neutral:
        return (fg: AppColors.neutral, bg: AppColors.neutralBg, label: '-');
      case AppStatus.onProgress:
        return (
          fg: AppColors.inProgress,
          bg: AppColors.inProgressBg,
          label: 'Diproses'
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final d = _data;
    final text = label ?? d.label;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration:
          BoxDecoration(color: d.bg, borderRadius: BorderRadius.circular(6)),
      child: Text(text,
          style: TextStyle(
              fontSize: 10, fontWeight: FontWeight.w700, color: d.fg)),
    );
  }
}
