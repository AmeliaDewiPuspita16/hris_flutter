import 'package:flutter/material.dart';

import '../../../../../../core/theme/app_colors.dart';

/// Status satu request IT/Media, dari `{code, label}` di respons.
///
/// Sengaja bukan enum. Label yang tampil selalu milik server, jadi kode baru
/// yang ditambahkan backend tetap terbaca di layar tanpa aplikasi perlu
/// dirilis ulang — pola sama dengan `PrStatus` di EProcurement.
///
/// Baru dua kode yang diketahui pasti artinya: "done" (sudah dikerjakan tim
/// IT, menunggu rating dari user) dan "finished" (sudah dinilai/ditutup).
/// Kode lain (mis. tahap menunggu HOD, sedang dikerjakan) belum ada
/// contohnya — daripada menebak warnanya, kode tak dikenal jatuh ke netral;
/// labelnya tetap benar karena datang dari server.
class ItRequestStatus {
  const ItRequestStatus({required this.code, required this.label});

  final String code;
  final String label;

  factory ItRequestStatus.fromJson(Map<String, dynamic>? json) {
    final code = '${json?['code'] ?? ''}';
    final serverLabel = json?['label'];
    final label = serverLabel is String && serverLabel.isNotEmpty
        ? serverLabel
        : (code.isEmpty ? 'Tidak diketahui' : code);

    return ItRequestStatus(code: code, label: label);
  }

  Color get color => switch (code) {
        'finished' => AppColors.present,
        'done' => AppColors.accent,
        'rejected' || 'cancelled' => AppColors.rejected,
        _ => AppColors.neutral,
      };

  Color get background => switch (code) {
        'finished' => AppColors.presentBg,
        'done' => AppColors.accentBg,
        'rejected' || 'cancelled' => AppColors.rejectedBg,
        _ => AppColors.neutralBg,
      };
}
