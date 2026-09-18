import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';

/// Keadaan satu titik di timeline — dipakai bersama oleh "Approval Progress"
/// (tahap approval) dan "Progress Dokumen" (PR -> Vendor Tally -> PO ->
/// Goods Receipt), karena arti ketiga keadaannya sama persis.
enum ProgressState {
  done,
  current,
  pending;

  Color get color => switch (this) {
        ProgressState.done => AppColors.present,
        ProgressState.current => AppColors.accent,
        ProgressState.pending => AppColors.neutral,
      };

  Color get background => switch (this) {
        ProgressState.done => AppColors.presentBg,
        ProgressState.current => AppColors.accentBg,
        ProgressState.pending => AppColors.neutralBg,
      };

  /// Titik yang sudah/sedang berjalan digambar padat, yang belum diproses
  /// hanya lingkaran samar — supaya posisi PR kelihatan tanpa membaca teks.
  bool get isFilled => this != ProgressState.pending;
}
