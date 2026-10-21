import 'package:flutter/material.dart';

import '../../../../../../core/theme/app_colors.dart';

/// Status satu request IT/Media, dari `{code, label}` di respons.
///
/// Sengaja bukan enum. Label yang tampil selalu milik server, jadi kode baru
/// yang ditambahkan backend tetap terbaca di layar tanpa aplikasi perlu
/// dirilis ulang — pola sama dengan `PrStatus` di EProcurement.
///
/// Kode yang diketahui pasti artinya: "waiting" (belum direspons tim IT),
/// "progress" (sedang dikerjakan, lih. `ItRequestRepository.respond`),
/// "wait_checked" (sudah complete, menunggu verifikasi terpisah — lih.
/// `ItRequestRepository.complete`), "done" (sudah dikerjakan, menunggu
/// rating dari user), dan "finished" (sudah dinilai/ditutup). Kode lain
/// yang belum ada contohnya jatuh ke netral — daripada menebak warnanya,
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
        : (code.isEmpty ? 'Unknown' : code);

    return ItRequestStatus(code: code, label: label);
  }

  Color get color => switch (code) {
        'finished' => AppColors.present,
        'done' || 'wait_checked' => AppColors.accent,
        'progress' => AppColors.inProgress,
        'waiting' => AppColors.pending,
        'rejected' || 'cancelled' => AppColors.rejected,
        _ => AppColors.neutral,
      };

  Color get background => switch (code) {
        'finished' => AppColors.presentBg,
        'done' || 'wait_checked' => AppColors.accentBg,
        'progress' => AppColors.inProgressBg,
        'waiting' => AppColors.pendingBg,
        'rejected' || 'cancelled' => AppColors.rejectedBg,
        _ => AppColors.neutralBg,
      };
}
